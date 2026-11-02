# DSD project recovery

Recovered on 2026-11-02 from `Desktop/epfl/ma1/DSD`, using the existing private repository `ri-ru/DSD`. Existing tracked files were not replaced. The main project files retain their original relative directory structure under `recovered/dsd_ill/`. Distinct source variants from the local `github/DSD` export and the neighboring lab folders are preserved under their corresponding paths in `recovered/`; files identical to already preserved contents are not duplicated.

## What was found

- The folder named `FINAL FILES` contains the final-design VHDL package, VGA controller, Pong state machine, Mandelbrot engine, and top-level integration, together with a Vivado project, clock/memory IP configuration, constraints, board definitions, and a Mandelbrot testbench.
- Other folders contain earlier Pong/VGA designs, lab handouts, image-to-memory tools and initialization data, and Jan/Dimitri source backups. They are preserved as historical variants, not substituted for the final-design files.
- `Slides and video` contains three original H.264/AAC MKV recordings by Max and three original audio recordings by Max/Dimitri. The filenames distinguish introduction, Pong logic, conclusion, memory, and Mandelbrot sections.
- `Final presentation.pptx` and `Presentation structure.docx` have been downloaded from their cloud placeholders and recovered. The presentation identifies the 2024 project as “VHDL PONG GAME,” by Jan Juraszek, Max Peseux, and Dimitri Pelgrin, Group R. This attribution is preserved from the original slides.

No combined final submission video has been identified. The project materials are not represented as proof that a final submission was made.

## Preservation policy

Source/design files, testbenches, IP configurations, constraints, board metadata, project descriptions, MATLAB helpers, small project images, memory initialization files, handouts, presentation materials, and original recordings are included when their content is available.

Vivado simulation/build/cache directories (`.cache`, `.gen`, `.runs`, `.sim`, `.hw`, `.ip_user_files`, and `.Xil`), logs, generated executables, and temporary outputs are excluded. They are not required to preserve the authored design, and remain in the original Desktop folder. The existing repository's tracked historical material is unchanged.

## Verification

Every copied file is checked against its source using SHA-256. The manifest records its original relative path, repository path, byte size, and digest. Pending cloud-only items are explicitly recorded rather than replaced with empty files.

All three video files and all three audio files were successfully inspected with `ffprobe` and fully decoded with `ffmpeg` without reported errors. The original videos contain 1920×1080 H.264 video and AAC audio. Their reported durations are approximately 36.750, 96.984, and 39.317 seconds. The audio durations are approximately 60.245, 85.803, and 14.060 seconds. The recovered PPTX/DOCX presentation files passed ZIP integrity checks.

Vivado is not installed on this machine, so synthesis, implementation, hardware programming, and board-level operation have not been rerun. Historical XPR/Tcl files retain original absolute/relative paths and may need source relocation in Vivado. No original HDL has been edited as part of this recovery.
