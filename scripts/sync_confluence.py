#!/usr/bin/env python3
"""
Confluence Documentation Synchronizer
Synchronizes Markdown files and Mermaid diagrams to an Atlassian Confluence space.
"""

import argparse
import base64
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
import urllib.error
from pathlib import Path
from typing import Dict, List, Optional, Tuple

try:
    import markdown
except ImportError:
    markdown = None


class ConfluenceClient:
    def __init__(self, base_url: str, email: str, api_token: str):
        self.base_url = base_url.rstrip("/")
        if not self.base_url.endswith("/wiki"):
            self.wiki_url = f"{self.base_url}/wiki"
        else:
            self.wiki_url = self.base_url
        self.email = email
        self.api_token = api_token
        auth_bytes = f"{email}:{api_token}".encode("utf-8")
        self.auth_header = f"Basic {base64.b64encode(auth_bytes).decode('ascii')}"

    def _request(self, method: str, path: str, data: Optional[dict] = None, headers: Optional[dict] = None) -> dict:
        url = f"{self.wiki_url}{path}"
        req_headers = {
            "Authorization": self.auth_header,
            "Accept": "application/json",
        }
        if headers:
            req_headers.update(headers)

        body = None
        if data is not None:
            req_headers["Content-Type"] = "application/json"
            body = json.dumps(data).encode("utf-8")

        req = urllib.request.Request(url, data=body, headers=req_headers, method=method)
        try:
            with urllib.request.urlopen(req) as resp:
                resp_text = resp.read().decode("utf-8")
                return json.loads(resp_text) if resp_text else {}
        except urllib.error.HTTPError as e:
            err_msg = e.read().decode("utf-8", errors="ignore")
            raise RuntimeError(f"HTTP {e.code} for {method} {url}: {err_msg}")

    def get_space(self, space_key: str) -> dict:
        """Find space metadata and ID by space key."""
        res = self._request("GET", f"/api/v2/spaces?keys={urllib.parse.quote(space_key)}")
        results = res.get("results", [])
        if not results:
            # Fallback list all spaces and search
            res = self._request("GET", "/api/v2/spaces")
            for s in res.get("results", []):
                if s.get("key", "").upper() == space_key.upper():
                    return s
            raise ValueError(f"Confluence space '{space_key}' not found.")
        return results[0]

    def find_page_by_title(self, space_id: str, title: str) -> Optional[dict]:
        """Search for an existing page by title in a space."""
        query = f"spaceId={space_id}&title={urllib.parse.quote(title)}"
        res = self._request("GET", f"/api/v2/pages?{query}")
        results = res.get("results", [])
        return results[0] if results else None

    def get_page_version(self, page_id: str) -> int:
        """Get current version number of a page."""
        page = self._request("GET", f"/api/v2/pages/{page_id}")
        return page.get("version", {}).get("number", 1)

    def create_page(self, space_id: str, title: str, storage_content: str, parent_id: Optional[str] = None) -> dict:
        """Create a new page."""
        payload = {
            "spaceId": space_id,
            "status": "current",
            "title": title,
            "body": {
                "representation": "storage",
                "value": storage_content
            }
        }
        if parent_id:
            payload["parentId"] = str(parent_id)
        return self._request("POST", "/api/v2/pages", data=payload)

    def update_page(self, page_id: str, space_id: str, title: str, storage_content: str, parent_id: Optional[str] = None) -> dict:
        """Update an existing page with incremented version."""
        curr_ver = self.get_page_version(page_id)
        payload = {
            "id": str(page_id),
            "status": "current",
            "title": title,
            "spaceId": space_id,
            "body": {
                "representation": "storage",
                "value": storage_content
            },
            "version": {
                "number": curr_ver + 1,
                "message": "Automated sync from repository"
            }
        }
        if parent_id:
            payload["parentId"] = str(parent_id)
        return self._request("PUT", f"/api/v2/pages/{page_id}", data=payload)

    def upload_attachment(self, page_id: str, filename: str, file_bytes: bytes, comment: str = "") -> dict:
        """Upload a file attachment to a Confluence page."""
        boundary = f"----SyncBoundary{hashlib.md5(filename.encode()).hexdigest()[:12]}"
        parts = [
            f"--{boundary}\r\n".encode("utf-8"),
            f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'.encode("utf-8"),
            b"Content-Type: image/png\r\n\r\n",
            file_bytes,
            b"\r\n",
            f"--{boundary}\r\n".encode("utf-8"),
            b'Content-Disposition: form-data; name="comment"\r\n\r\n',
            comment.encode("utf-8"),
            b"\r\n",
            f"--{boundary}--\r\n".encode("utf-8")
        ]
        multipart_data = b"".join(parts)
        url = f"{self.wiki_url}/rest/api/content/{page_id}/child/attachment"

        req = urllib.request.Request(
            url,
            data=multipart_data,
            headers={
                "Authorization": self.auth_header,
                "X-Atlassian-Token": "nocheck",
                "Content-Type": f"multipart/form-data; boundary={boundary}",
                "Accept": "application/json"
            },
            method="POST"
        )
        try:
            with urllib.request.urlopen(req) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            err = e.read().decode("utf-8", errors="ignore")
            raise RuntimeError(f"Failed to upload attachment {filename}: {err}")


def render_mermaid(diagram_code: str, output_path: str) -> bool:
    """Render Mermaid diagram code to PNG using mmdc or mermaid.ink fallback."""
    # Method 1: Local mmdc CLI
    try:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".mmd", delete=False) as tf:
            tf.write(diagram_code)
            temp_mmd = tf.name

        cmd = ["npx", "-y", "@mermaid-js/mermaid-cli", "-i", temp_mmd, "-o", output_path, "-b", "white", "--scale", "2"]
        res = subprocess.run(cmd, capture_output=True, timeout=30)
        if os.path.exists(temp_mmd):
            os.unlink(temp_mmd)
        if res.returncode == 0 and os.path.exists(output_path) and os.path.getsize(output_path) > 0:
            return True
    except Exception:
        pass

    # Method 2: mermaid.ink fallback service
    try:
        payload = {"code": diagram_code, "mermaid": {"theme": "default"}}
        b64 = base64.urlsafe_b64encode(json.dumps(payload).encode("utf-8")).decode("ascii")
        url = f"https://mermaid.ink/img/{b64}?bgColor=FFFFFF"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=20) as resp:
            with open(output_path, "wb") as f:
                f.write(resp.read())
            return os.path.exists(output_path) and os.path.getsize(output_path) > 0
    except Exception as e:
        print(f"Warning: Failed to render mermaid diagram via mermaid.ink: {e}", file=sys.stderr)
        return False


def extract_title(content: str, filepath: Path) -> Tuple[str, str]:
    """Extract page title and body from frontmatter, first H1, or filename/parent directory."""
    body = content
    # Check frontmatter
    fm_match = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)$", content, flags=re.DOTALL)
    if fm_match:
        fm_text = fm_match.group(1)
        body = fm_match.group(2)
        title_match = re.search(r"^(?:title|name):\s*[\"']?(.*?)[\"']?$", fm_text, re.MULTILINE)
        if title_match:
            raw_title = title_match.group(1).strip()
            # If it's a skill or agent, format nicely
            if "skills" in filepath.parts:
                return f"Skill: {raw_title.title()}", body.strip()
            elif "agents" in filepath.parts:
                return f"Agent: {raw_title.title()}", body.strip()
            return raw_title, body.strip()

    # Check first # Heading
    h1_match = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
    if h1_match:
        title = h1_match.group(1).strip()
        # Remove the first H1 from body so it doesn't duplicate Confluence's page title
        body = body[:h1_match.start()] + body[h1_match.end():]
        return title, body.strip()

    # Fallback to parent directory + filename
    raw_name = filepath.stem
    if raw_name.upper() in ["README", "SKILL"]:
        parent_name = filepath.parent.name if filepath.parent != Path(".") else "Overview"
        clean_title = f"{parent_name.replace('-', ' ').title()} ({raw_name.title()})"
    else:
        clean_title = raw_name.replace("-", " ").replace("_", " ").title()
    return clean_title, body.strip()


def markdown_to_storage_format(md_text: str, mermaid_images: Dict[str, str]) -> str:
    """Convert Markdown to Confluence Storage Format XHTML."""
    # Convert markdown to basic HTML
    if markdown:
        html = markdown.markdown(md_text, extensions=["tables", "fenced_code", "nl2br", "sane_lists"])
    else:
        # Minimal fallback
        html = md_text.replace("\n\n", "</p><p>")
        html = f"<p>{html}</p>"

    # Replace mermaid tokens with Confluence image macros
    for placeholder, img_name in mermaid_images.items():
        macro = f'<p><ac:image ac:align="center"><ri:attachment ri:filename="{img_name}" /></ac:image></p>'
        html = html.replace(f"<p>{placeholder}</p>", macro)
        html = html.replace(placeholder, macro)

    # Wrap in clean container
    return f'<div class="wiki-content">{html}</div>'


def process_markdown_file(filepath: Path) -> Tuple[str, str, Dict[str, bytes]]:
    """Process markdown file, extract diagrams, and render images."""
    with open(filepath, "r", encoding="utf-8") as f:
        raw_content = f.read()

    title, body = extract_title(raw_content, filepath)

    mermaid_images: Dict[str, str] = {} # placeholder -> image_name
    rendered_attachments: Dict[str, bytes] = {} # image_name -> bytes

    diagram_idx = 1
    # Match ```mermaid ... ```
    mermaid_pattern = re.compile(r"```mermaid\s*\n(.*?)\n```", flags=re.DOTALL)
    
    def replacer(match):
        nonlocal diagram_idx
        diagram_code = match.group(1).strip()
        img_name = f"{filepath.stem}_diagram_{diagram_idx}.png"
        placeholder = f"__MERMAID_DIAGRAM_{diagram_idx}__"
        diagram_idx += 1

        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tf:
            tmp_png = tf.name

        if render_mermaid(diagram_code, tmp_png):
            with open(tmp_png, "rb") as f:
                rendered_attachments[img_name] = f.read()
            mermaid_images[placeholder] = img_name
            os.unlink(tmp_png)
            return f"\n\n{placeholder}\n\n"
        else:
            if os.path.exists(tmp_png):
                os.unlink(tmp_png)
            # If render fails, fallback to code block
            return f"```mermaid\n{diagram_code}\n```"

    processed_body = mermaid_pattern.sub(replacer, body)
    storage_xml = markdown_to_storage_format(processed_body, mermaid_images)

    return title, storage_xml, rendered_attachments


def main():
    parser = argparse.ArgumentParser(description="Sync Markdown and Mermaid to Confluence")
    parser.add_argument("--space-key", default=os.getenv("CONFLUENCE_SPACE_KEY", "OOP"), help="Confluence Space Key")
    parser.add_argument("--parent-title", default=os.getenv("CONFLUENCE_PARENT_TITLE", ""), help="Top-level parent page title")
    parser.add_argument("--docs-root", default=".", help="Root directory containing markdown files")
    parser.add_argument("--backfill", action="store_true", help="Sync all markdown files in directory tree")
    parser.add_argument("--files", nargs="*", default=[], help="Specific files to sync")
    parser.add_argument("--dry-run", action="store_true", help="Dry run without writing to Confluence")
    args = parser.parse_args()

    # Resolve credentials
    email = os.getenv("ATLASSIAN_EMAIL") or os.getenv("JIRA_USERNAME") or os.getenv("CONFLUENCE_USERNAME")
    token = os.getenv("ATLASSIAN_API_KEY") or os.getenv("JIRA_API_TOKEN") or os.getenv("CONFLUENCE_API_TOKEN")
    url = os.getenv("CONFLUENCE_URL") or os.getenv("JIRA_URL") or "https://vikash1a2b3c.atlassian.net/wiki"

    if not args.dry_run and (not email or not token):
        print("Error: Missing credentials. Please set ATLASSIAN_EMAIL and ATLASSIAN_API_KEY environment variables.", file=sys.stderr)
        sys.exit(1)

    # Discover files
    files_to_sync: List[Path] = []
    if args.files:
        for f in args.files:
            p = Path(f)
            if p.suffix.lower() in [".md", ".mdx"] and p.is_file():
                files_to_sync.append(p)
    elif args.backfill:
        root_path = Path(args.docs_root)
        for p in root_path.rglob("*.md"):
            if not any(part.startswith(".") for part in p.parts):
                files_to_sync.append(p)
    else:
        # Default to all markdown files if none specified
        root_path = Path(args.docs_root)
        for p in root_path.rglob("*.md"):
            if not any(part.startswith(".") for part in p.parts):
                files_to_sync.append(p)

    if not files_to_sync:
        print("No markdown files found to sync.")
        return

    print(f"Found {len(files_to_sync)} file(s) to sync to Confluence Space [{args.space_key}]:")
    for f in files_to_sync:
        print(f"  - {f}")

    if args.dry_run:
        print("\n[DRY RUN] Simulating parsing and diagram generation...")
        for f in files_to_sync:
            title, storage, attachments = process_markdown_file(f)
            print(f"  Page: '{title}' | Diagrams extracted: {len(attachments)}")
        print("\nDry run completed successfully.")
        return

    client = ConfluenceClient(url, email, token)
    space = client.get_space(args.space_key)
    space_id = space["id"]
    print(f"\nConnected to Confluence Space: '{space.get('name')}' (ID: {space_id})")

    # Parent page lookup / creation if specified
    root_parent_id = None
    if args.parent_title:
        parent_page = client.find_page_by_title(space_id, args.parent_title)
        if parent_page:
            root_parent_id = parent_page["id"]
            print(f"Root parent page found: '{args.parent_title}' (ID: {root_parent_id})")
        else:
            print(f"Creating root parent page: '{args.parent_title}'...")
            p_res = client.create_page(space_id, args.parent_title, f"<p>Documentation root for repository.</p>")
            root_parent_id = p_res["id"]
            print(f"Created parent page (ID: {root_parent_id})")

    # Sync each document
    synced_pages = 0
    for f in sorted(files_to_sync):
        try:
            title, storage_content, attachments = process_markdown_file(f)
            print(f"\nProcessing '{f}' -> Page Title: '{title}'")

            existing = client.find_page_by_title(space_id, title)
            if existing:
                page_id = existing["id"]
                print(f"  Updating existing page (ID: {page_id})...")
                res = client.update_page(page_id, space_id, title, storage_content, parent_id=root_parent_id)
            else:
                print(f"  Creating new page...")
                res = client.create_page(space_id, title, storage_content, parent_id=root_parent_id)
                page_id = res["id"]

            webui = res.get("_links", {}).get("webui", "")
            page_url = f"{url.rstrip('/')}{webui}" if webui.startswith("/") else f"{url.rstrip('/')}/{webui}"

            # Upload attachments (diagrams)
            if attachments:
                print(f"  Uploading {len(attachments)} diagram attachment(s)...")
                for img_name, img_bytes in attachments.items():
                    client.upload_attachment(page_id, img_name, img_bytes, comment="Automated mermaid render")
                    print(f"    Uploaded: {img_name}")

            print(f"  ✔ Successfully synced: {page_url}")
            synced_pages += 1
        except Exception as e:
            print(f"  ✖ Error syncing {f}: {e}", file=sys.stderr)

    print(f"\n✅ Synchronization complete! {synced_pages}/{len(files_to_sync)} pages synced.")


if __name__ == "__main__":
    main()
