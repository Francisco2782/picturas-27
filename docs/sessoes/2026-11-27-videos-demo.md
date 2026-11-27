# Browser demo videos

Copied four existing synthetic fixtures from `samples/video/` to `demo/` with numbered, descriptive names. The two short clips cover editing with audio and MOV input. The other two cover upload rejection at the free account's 60-second limit and for an invalid container.

| Demo file | Original fixture | Observed locally |
| --- | --- | --- |
| `01-edicao-com-audio.mp4` | `sample_10s_720p.mp4` | 10 s, 1280×720, H.264 and AAC |
| `02-upload-mov.mov` | `sample_6s.mov` | 6 s, 640×480, H.264 and AAC |
| `03-limite-conta-free.mp4` | `too_long_90s.mp4` | 90 s, 320×240, H.264 |
| `04-ficheiro-corrompido.mp4` | `corrupted.mp4` | Probe failed because the container lacks a moov atom |

Used `mkdir -p demo` and `cp -n` to create the folder and copies. Ran `cmp` on all four source and destination pairs, with no differences. Ran `ffprobe -v error -show_entries format=filename,duration:stream=codec_type,codec_name,width,height -of compact "$demo_file"` on the first three and `ffprobe -v error` on the corrupt fixture. Fully decoded the two short clips with `ffmpeg -v error -xerror -i "$demo_file" -map '0:v' -map '0:a?' -f null -`. Both decoded without errors. `ls -lh demo` reported 4.3 MB.

The [editor follow-up](2026-11-27-ajustes-demo-editor.md) records the later Chromium checks for the MOV result download and the Free-account subtitle run. Playback with audio for both downloads and the two upload-error cases remain manual checks. The [sample guide](../../samples/video/README.md#browser-demo) recreates all five local demo files.
