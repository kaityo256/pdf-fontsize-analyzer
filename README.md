# Font Size Analyzer for PDF Documents

A Ruby script that analyzes a given PDF file and reports the number of characters used for each font size, along with the average font size.

## Features

- Counts the number of characters used per font size.
- Optionally rounds font sizes to the nearest step value.
- Calculates and displays the average font size.
- Supports verbose output for debugging or detailed inspection.

## Requirements

This script depends on the [`hexapdf`](https://github.com/gettalong/hexapdf) gem for PDF parsing.

To install dependencies, run:

```sh
bundle install
```

## Usage

```sh
ruby analyze_font_size.rb [options] filename.pdf
```

## Options

```txt
-v, --verbose                    Enable verbose output
-r, --round-size[=STEP]          Round font sizes to the nearest STEP (e.g., 0.5)
-h, --help                       Show this help message
```

## Example

Running the script on `samples/latex.pdf`:

```sh
$ ruby analyze_font_size.rb samples/latex.pdf
```

Output:
```txt
Font Size    Character count
9.2125       8
9.9626       11

Average Size: 9.65
```

With rounding enabled (default step is 0.5):
```sh
$ ruby analyze_font_size.rb -r samples/latex.pdf
```

Output:
```txt
Font Size    Character count
9.0          8
10.0         11

Average Size: 9.58
```

## Known Issues

PDF files generated from some applications, such as **Microsoft Word on macOS** may not report character counts accurately. As a result, the script may undercount or fail to detect characters in such files.

## License

This project is licensed under the MIT License.
