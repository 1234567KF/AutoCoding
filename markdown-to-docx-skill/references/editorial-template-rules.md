# DOCX Template Rules

This file records Word-export rules that the template rendering pipeline tries to enforce.

## Non-negotiable layout rules

- Prefer the latest reviewed `.docx` as the `--reference-doc` when available; treat a `.dotx` as a base template.
- If the reference template contains Word shortcut bindings, generated `.docx` files should retain `word/customizations.xml` so style hotkeys such as `ALT+1` remain available. The render pipeline auto-copies these bindings when the reference template already contains them.
- Replace only the default header text. Keep first-page and even-page headers blank unless the editor file shows otherwise.
- Strip Pandoc body styles such as `FirstParagraph`, `BodyText`, and `Compact` so the reference template's body style wins.
- Keep screenshot/image paragraphs mapped to the custom style `图`.
- Map figure captions to the custom style `图题`.
- Apply Word `keep with next` to every `图` paragraph so each image stays on the same page as the following figure caption.
- Apply Word `keep with next` to every `表题1-1` paragraph so each table caption stays on the same page as the following table.
- Map only real note/warning labels such as `注：`, `注意：`, and `关键注意：` to the custom style `注意`.
- Keep generic explanatory lead-ins such as `说明：` and `解释：` in body text, or rewrite them into prose in the source manuscript.
- Remove the first-line indent from exported code-block paragraphs (`Source Code` / `代码清单`) so code starts flush-left inside the code block.
- Clear first-line indent for all paragraphs inside Word table cells so table content does not visually inherit body-text indentation.
- Align unordered-list text with the Chinese body-text first-line indent. Avoid Word's default deep bullet indentation; level-0 bullet text should start at the same visual column as a normal Chinese paragraph first line.

## Figure and table caption rules

- Figure captions must use the short form `图1-1 标题`.
- Table captions must use the short form `表1-1 标题`.
- Use hyphen serials such as `1-1`, not dotted serials such as `1.1`.
- Do not place explanatory text inside figure captions.
- If a source figure caption contains a second explanatory sentence, move that sentence into body text and keep only the short title in the caption.
- Figure and table captions should not end with a full stop.

## Editorial writing rules reflected in export

- When the text says `确认`, `确保`, or `检查`, provide an explicit verification action or acceptance signal nearby instead of leaving the confirmation vague.
- Prefer `如图1-1所示` style references in body text when explanation needs to point readers back to a screenshot.
- Treat structural rewrites separately from template rules. Examples: adding bridge sentences, converting numbered explanation lists into prose, or rewriting a subsection outline.
