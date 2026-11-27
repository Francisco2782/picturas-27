# Sample videos for manual tests

| File | Purpose | Expected result |
|---|---|---|
| `sample_10s_720p.mp4` | Valid video, 10 s, 1280x720, 30 fps, with audio | Accepted; can be edited, previewed, trimmed and exported |
| `sample_6s.mov` | MOV input | Accepted; the result is exported as MP4 |
| `too_long_90s.mp4` | Exceeds the 60 s limit of the free profile | Rejected on upload with the reason |
| `corrupted.mp4` | Corrupted file | Rejected on upload |
| `speech_mandela_177s_1080p.webm` | Real WebM (VP9 + Opus), 2 min 57 s, 1920x1080, English narration | Rejected on the free profile (over 60 s); accepted on premium. Good input for **Automatic subtitles** and **Extract frames** |

The synthetic samples were generated with ffmpeg (`testsrc2`, `smptebars`, `sine`).

`speech_mandela_177s_1080p.webm` is
[“How Nelson Mandela Fought for Equality and Freedom”](https://commons.wikimedia.org/wiki/File:How_Nelson_Mandela_Fought_for_Equality_and_Freedom.webm)
by [simpleshow foundation](https://www.youtube.com/user/simpleshowfoundation), licensed under
[CC BY 3.0](https://creativecommons.org/licenses/by/3.0/), via Wikimedia Commons. Unmodified.

## Browser demo

From the repository root, recreate the numbered files in the Git-ignored `demo/`
directory. The last command makes a 45-second excerpt of the same credited speech
clip for a Free account.

```sh
mkdir -p demo
cp -i samples/video/sample_10s_720p.mp4 demo/01-edicao-com-audio.mp4
cp -i samples/video/sample_6s.mov demo/02-upload-mov.mov
cp -i samples/video/too_long_90s.mp4 demo/03-limite-conta-free.mp4
cp -i samples/video/corrupted.mp4 demo/04-ficheiro-corrompido.mp4
ffmpeg -n -v error -i samples/video/speech_mandela_177s_1080p.webm \
  -t 45 -map 0:v:0 -map 0:a:0 -c copy demo/05-fala-45s-conta-free.webm
```

Use the first two files to check editing and MP4 downloads with audio. With a
Free account, try the 90-second clip and the corrupt file separately to check
the upload errors. The speech excerpt is suitable for checking subtitle
processing and cancellation within the Free upload duration limit.
