"""
一键式 Markdown 转 Word 工具
===========================

用户只需提供：
1. Markdown 文件路径
2. 参考样式 DOCX 文件路径

脚本自动完成：
1. 分析参考文档的样式
2. 生成 Pandoc 专用模板
3. 执行转换
4. 应用样式后处理

使用方法：
-----------
python 一键Markdown转Word.py <markdown文件> <参考docx文件> [输出docx文件]

示例：
--------
python 一键Markdown转Word.py 手册.md 标准.docx
python 一键Markdown转Word.py 手册.md 标准.docx 输出.docx
"""

import os
import sys
import json
import tempfile
from pathlib import Path
from docx import Document
from docx.shared import Pt, Inches, RGBColor, Emu
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.enum.style import WD_STYLE_TYPE

# Pandoc 路径
PANDOC_PATH = r"C:\Users\KF\AppData\Local\Temp\pandoc\pandoc-3.2\pandoc.exe"


class StyleAnalyzer:
    """样式分析器 - 自动提取参考文档的样式"""

    def __init__(self, docx_path):
        self.doc = Document(docx_path)
        self.styles = {}

    def extract_styles(self):
        """提取所有关键样式"""
        print("正在分析参考文档样式...")

        # 提取 Normal 样式
        if 'Normal' in [s.name for s in self.doc.styles]:
            normal = self.doc.styles['Normal']
            self.styles['Normal'] = {
                'font_name': normal.font.name or 'Times New Roman',
                'font_size': self._get_font_size(normal.font.size),
                'bold': normal.font.bold,
                'first_line_indent': self._get_indent(normal.paragraph_format.first_line_indent),
                'line_spacing': self._get_line_spacing(normal.paragraph_format.line_spacing),
            }

        # 提取 Heading 1
        if 'Heading 1' in [s.name for s in self.doc.styles]:
            h1 = self.doc.styles['Heading 1']
            self.styles['Heading 1'] = {
                'font_name': h1.font.name or '黑体',
                'font_size': self._get_font_size(h1.font.size),
                'bold': h1.font.bold if h1.font.bold is not None else True,
                'space_before': self._get_space(h1.paragraph_format.space_before),
                'space_after': self._get_space(h1.paragraph_format.space_after),
            }

        # 提取 Heading 2
        if 'Heading 2' in [s.name for s in self.doc.styles]:
            h2 = self.doc.styles['Heading 2']
            self.styles['Heading 2'] = {
                'font_name': h2.font.name or '微软雅黑',
                'font_size': self._get_font_size(h2.font.size),
                'bold': h2.font.bold,
                'space_before': self._get_space(h2.paragraph_format.space_before),
                'space_after': self._get_space(h2.paragraph_format.space_after),
            }

        # 提取 Heading 3
        if 'Heading 3' in [s.name for s in self.doc.styles]:
            h3 = self.doc.styles['Heading 3']
            self.styles['Heading 3'] = {
                'font_name': h3.font.name or '微软雅黑',
                'font_size': self._get_font_size(h3.font.size),
                'bold': h3.font.bold,
            }

        # 提取 List Bullet
        if 'List Bullet' in [s.name for s in self.doc.styles]:
            lb = self.doc.styles['List Bullet']
            self.styles['List Bullet'] = {
                'font_name': lb.font.name or '宋体',
                'font_size': self._get_font_size(lb.font.size),
                'left_indent': self._get_indent(lb.paragraph_format.left_indent),
            }

        # 提取 List Number
        if 'List Number' in [s.name for s in self.doc.styles]:
            ln = self.doc.styles['List Number']
            self.styles['List Number'] = {
                'font_name': ln.font.name or '宋体',
                'font_size': self._get_font_size(ln.font.size),
            }

        # 提取 Code Block 样式
        if 'Source Code' in [s.name for s in self.doc.styles]:
            sc = self.doc.styles['Source Code']
            self.styles['Source Code'] = {
                'font_name': sc.font.name or 'Consolas',
                'font_size': self._get_font_size(sc.font.size),
            }

        print(f"✓ 提取了 {len(self.styles)} 种样式")
        return self.styles

    def _get_font_size(self, size):
        """获取字体大小（pt）"""
        if size is None:
            return None
        # size 可能是 Pt 对象或 EMU
        if hasattr(size, 'pt'):
            return size.pt
        # 假设是 EMU，转换为 pt
        return size / 12700

    def _get_indent(self, indent):
        """获取缩进值"""
        if indent is None:
            return None
        if hasattr(indent, 'pt'):
            return indent.pt
        return indent / 12700

    def _get_line_spacing(self, spacing):
        """获取行距"""
        if spacing is None:
            return 1.5  # 默认 1.5 倍
        if isinstance(spacing, (int, float)):
            return spacing
        return 1.5

    def _get_space(self, space):
        """获取间距"""
        if space is None:
            return 0
        if hasattr(space, 'pt'):
            return space.pt
        return space / 12700

    def print_styles(self):
        """打印提取的样式"""
        print("\n" + "="*60)
        print("提取的样式详情")
        print("="*60)

        for style_name, style_props in self.styles.items():
            print(f"\n{style_name}:")
            for prop, value in style_props.items():
                print(f"  {prop}: {value}")


class TemplateGenerator:
    """模板生成器 - 根据分析结果生成 Pandoc 模板"""

    def __init__(self, styles):
        self.styles = styles

    def generate_template_docx(self, output_path):
        """生成 Word 模板文件"""
        print(f"\n正在生成模板: {output_path}")

        # 创建新文档
        doc = Document()

        # 应用 Normal 样式到默认样式
        if 'Normal' in self.styles:
            style = self.styles['Normal']
            normal = doc.styles['Normal']
            normal.font.name = style.get('font_name', 'Times New Roman')
            normal.font.size = Pt(style.get('font_size', 10.75))
            normal.paragraph_format.first_line_indent = Inches(0.3)  # 2字符
            normal.paragraph_format.line_spacing = style.get('line_spacing', 1.5)

        # 应用 Heading 1 样式
        if 'Heading 1' in self.styles:
            style = self.styles['Heading 1']
            h1 = doc.styles['Heading 1']
            h1.font.name = style.get('font_name', '黑体')
            h1.font.size = Pt(style.get('font_size', 15))
            h1.font.bold = style.get('bold', True)
            h1.paragraph_format.space_before = Pt(style.get('space_before', 11))
            h1.paragraph_format.space_after = Pt(style.get('space_after', 11))

        # 应用 Heading 2 样式
        if 'Heading 2' in self.styles:
            style = self.styles['Heading 2']
            h2 = doc.styles['Heading 2']
            h2.font.name = style.get('font_name', '微软雅黑')
            h2.font.size = Pt(style.get('font_size', 12.5))
            h2.font.bold = style.get('bold', False)
            h2.paragraph_format.space_before = Pt(style.get('space_before', 11.5))
            h2.paragraph_format.space_after = Pt(style.get('space_after', 11.5))

        # 应用 Heading 3 样式
        if 'Heading 3' in self.styles:
            style = self.styles['Heading 3']
            h3 = doc.styles['Heading 3']
            h3.font.name = style.get('font_name', '微软雅黑')
            h3.font.size = Pt(style.get('font_size', 11))
            h3.font.bold = style.get('bold', False)

        # 应用 List Bullet 样式
        if 'List Bullet' in self.styles:
            style = self.styles['List Bullet']
            lb = doc.styles['List Bullet']
            lb.font.name = style.get('font_name', '宋体')
            lb.font.size = Pt(style.get('font_size', 10.75))

        # 应用 Source Code 样式
        if 'Source Code' in self.styles:
            style = self.styles['Source Code']
            sc = doc.styles['Source Code']
            sc.font.name = style.get('font_name', 'Consolas')
            sc.font.size = Pt(style.get('font_size', 9))
            sc.paragraph_format.left_indent = Inches(0.3)

        # 保存模板
        doc.save(output_path)
        print(f"✓ 模板已生成")


class MarkdownToDocxConverter:
    """Markdown 转 DOCX 转换器"""

    def __init__(self, pandoc_path=PANDOC_PATH):
        self.pandoc_path = pandoc_path

    def convert(self, markdown_path, output_path, template_path=None, resource_path=None):
        """执行转换"""
        import subprocess

        # 构建命令
        cmd = [
            self.pandoc_path,
            markdown_path,
            "-o", output_path,
        ]

        # 添加模板
        if template_path:
            cmd.append(f"--reference-doc={template_path}")

        # 添加资源路径
        if resource_path:
            cmd.append(f"--resource-path={resource_path}")

        # 添加其他选项
        cmd.extend([
            "--standalone",
            "--toc",
            "--toc-depth=3",
            "--highlight-style=tango",
        ])

        print("\n正在执行 Pandoc 转换...")
        print(f"命令: {' '.join(str(x) for x in cmd)}")

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
                encoding='utf-8'
            )

            if result.stdout:
                print(result.stdout)

            print(f"\n✓ 转换成功！")
            print(f"输出文件: {output_path}")

            # 验证文件
            if os.path.exists(output_path):
                size = os.path.getsize(output_path)
                print(f"文件大小: {size:,} 字节")

            return output_path

        except subprocess.CalledProcessError as e:
            print(f"\n✗ 转换失败！")
            print(f"错误输出: {e.stderr}")
            raise


def one_click_convert(markdown_path, reference_docx_path, output_docx_path=None):
    """
    一键式转换函数

    Args:
        markdown_path: Markdown 文件路径
        reference_docx_path: 参考样式的 DOCX 文件路径
        output_docx_path: 输出 DOCX 文件路径（可选）

    Returns:
        输出文件的路径
    """

    print("="*70)
    print("一键式 Markdown 转 Word 工具")
    print("="*70)
    print()

    # 验证输入文件
    if not os.path.exists(markdown_path):
        raise FileNotFoundError(f"Markdown 文件不存在: {markdown_path}")

    if not os.path.exists(reference_docx_path):
        raise FileNotFoundError(f"参考 DOCX 文件不存在: {reference_docx_path}")

    # 生成输出文件名
    if output_docx_path is None:
        output_docx_path = Path(markdown_path).with_suffix('.docx')
        print(f"输出文件: {output_docx_path}")

    # 创建临时目录
    temp_dir = tempfile.mkdtemp(prefix='md2docx_')
    print(f"临时目录: {temp_dir}")

    try:
        # 步骤 1: 分析参考文档样式
        print("\n" + "="*70)
        print("步骤 1: 分析参考文档样式")
        print("="*70)
        analyzer = StyleAnalyzer(reference_docx_path)
        styles = analyzer.extract_styles()
        analyzer.print_styles()

        # 步骤 2: 生成模板
        print("\n" + "="*70)
        print("步骤 2: 生成 Pandoc 模板")
        print("="*70)
        template_path = os.path.join(temp_dir, 'generated_template.docx')
        generator = TemplateGenerator(styles)
        generator.generate_template_docx(template_path)

        # 步骤 3: 执行转换
        print("\n" + "="*70)
        print("步骤 3: 执行 Markdown → DOCX 转换")
        print("="*70)
        converter = MarkdownToDocxConverter()
        resource_path = os.path.dirname(os.path.abspath(markdown_path))
        converter.convert(
            markdown_path=markdown_path,
            output_path=output_docx_path,
            template_path=template_path,
            resource_path=resource_path
        )

        # 步骤 4: 完成
        print("\n" + "="*70)
        print("✓ 一键转换完成！")
        print("="*70)
        print(f"\n输出文件: {output_docx_path}")
        print(f"\n您可以直接打开此文件查看效果。")

        return output_docx_path

    finally:
        # 清理临时目录
        import shutil
        try:
            shutil.rmtree(temp_dir)
            print(f"\n已清理临时文件")
        except:
            pass


if __name__ == '__main__':
    # 解析命令行参数
    if len(sys.argv) < 3:
        # 如果没有参数，使用默认的测试文件
        print("使用默认测试文件...")
        markdown_file = r'd:\projects\AI编程智驾\AI编程智驾手册.md'
        reference_file = r'd:\projects\AI编程智驾\标准文件.docx'
        output_file = None
    else:
        markdown_file = sys.argv[1]
        reference_file = sys.argv[2]
        output_file = sys.argv[3] if len(sys.argv) > 3 else None

    # 执行转换
    try:
        result = one_click_convert(
            markdown_path=markdown_file,
            reference_docx_path=reference_file,
            output_docx_path=output_file
        )
        print(f"\n成功！输出文件: {result}")

    except Exception as e:
        print(f"\n转换失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
