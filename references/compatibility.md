# Verified local compatibility

Verified on 2026-09-26 with:

- `image-use` 0.29.2
- `chrome-use` 1.5.141
- Chrome extension 0.5.26
- Windows PowerShell and the Codex bundled Python runtime

The installed `C:\Users\21450\.codex\skills\image-use\image-use` contains narrow compatibility fixes for the current ChatGPT and `chrome-use` surfaces:

1. Accept `chrome-use eval` output prefixed with `eval @ `.
2. Recognize the ARIA/contenteditable composer when `#prompt-textarea` is absent.
3. Recognize `button[type="submit"][aria-label="Send"]` when the old send-button test id is absent.
4. Capture `chrome-use` output through temporary files on Windows so its long-lived daemon cannot keep a pipe open indefinitely.
5. Bring the ChatGPT tab to the foreground before submitting because hidden-tab clicks may be ignored.
6. Confirm submission using the new `/c/<id>` route, an empty composer, or the Stop control because current pages may expose zero `[data-message-author-role="user"]` nodes.

## Diagnostic order

1. Run `scripts/generate.ps1 -Doctor`.
2. Confirm that the relay is connected and the intended Chrome profile is signed in to `chatgpt.com`.
3. If a run says submission is uncertain, inspect the existing conversation before retrying. Never replay an uncertain Send.
4. If the composer or Send button moves again, inspect the live DOM and make the smallest selector change. Preserve the one-fill/one-click invariant.
5. Run the upstream `WebPromptSubmission` tests after changing submission logic. The upstream full suite currently has three unrelated Windows file-lock test failures.

Do not replace `--backend web` with `auto`; `auto` may consume Codex image usage when the browser path is unavailable.
