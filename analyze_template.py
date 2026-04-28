from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

doc = Document(r'd:\projects\AI编程智驾\标准文件.docx')

print('=== 模板详细样式分析 ===\n')

# 检查 Heading 1 样式
try:
    h1 = doc.styles['Heading 1']
    print('Heading 1 样式:')
    print(f'  字体: {h1.font.name}')
    print(f'  大小: {h1.font.size}')
    print(f'  粗体: {h1.font.bold}')
    try:
        if h1.font.color.rgb:
            print(f'  颜色: {h1.font.color.rgb}')
    except:
        print('  颜色: 默认')
    print(f'  段前: {h1.paragraph_format.space_before}')
    print(f'  段后: {h1.paragraph_format.space_after}')
except Exception as e:
    print(f'Heading 1: {e}')

print()

# 检查 Heading 2 样式
try:
    h2 = doc.styles['Heading 2']
    print('Heading 2 样式:')
    print(f'  字体: {h2.font.name}')
    print(f'  大小: {h2.font.size}')
    print(f'  粗体: {h2.font.bold}')
    print(f'  段前: {h2.paragraph_format.space_before}')
    print(f'  段后: {h2.paragraph_format.space_after}')
except Exception as e:
    print(f'Heading 2: {e}')

print()

# 检查 Normal 样式
try:
    normal = doc.styles['Normal']
    print('Normal（正文）样式:')
    print(f'  字体: {normal.font.name}')
    print(f'  大小: {normal.font.size}')
    print(f'  首行缩进: {normal.paragraph_format.first_line_indent}')
    print(f'  行距: {normal.paragraph_format.line_spacing}')
except Exception as e:
    print(f'Normal: {e}')

# 检查自定义样式
print()
print('=== 自定义样式检查 ===')

custom_styles = ['分点缩进正文', '表格文本']
for style_name in custom_styles:
    try:
        if style_name in [s.name for s in doc.styles]:
            style = doc.styles[style_name]
            print(f'\n{style_name}:')
            print(f'  字体: {style.font.name}')
            print(f'  大小: {style.font.size}')
            print(f'  首行缩进: {style.paragraph_format.first_line_indent}')
            print(f'  左缩进: {style.paragraph_format.left_indent}')
    except Exception as e:
        print(f'{style_name}: {e}')

print('\n=== 文档内容示例 ===')
for i, para in enumerate(doc.paragraphs[:5]):
    if para.text.strip():
        print(f'\n段落 {i+1} (样式: {para.style.name}):')
        print(f'  {para.text[:100]}...' if len(para.text) > 100 else f'  {para.text}')
