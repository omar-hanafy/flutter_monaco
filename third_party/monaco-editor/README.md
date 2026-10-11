# monaco-editor (bundled)

`assets/monaco/min/` is the `min/` directory of the official npm release,
unmodified:

| Field | Value |
| --- | --- |
| Package | `monaco-editor@0.57.0` |
| Tarball | `monaco-editor-0.57.0.tgz` (`npm pack monaco-editor@0.57.0`) |
| shasum | `9889fb51ddc27fe90e6da0e96c237c852adc4654` |
| integrity | `sha512-5BkI9KGoqrNvBGUe15/QlZq3OooZ8WLg1AxTpaqHRCP3HNpzPPZKE2EDz8M7c+VRmCeUw1Brp4cx/PWm3kI/5A==` |

`.pubignore` keeps the files no runtime path loads (the AMD worker entries
and the UI translations under `vs/nls/`) out of the published package; the
repository copy stays byte-identical to the release.

Monaco Editor is MIT licensed ([LICENSE](LICENSE), also appended to the
package `LICENSE` so it appears in apps' license pages). The third-party
code it includes is listed in [ThirdPartyNotices.txt](ThirdPartyNotices.txt).
