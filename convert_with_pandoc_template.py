"""
Windows 版本的 Markdown 转 DOCX 模板转换脚本
使用 Pandoc + 模板文件 实现高度精确的样式控制
"""

import os
import sys
import subprocess
import tempfile
from pathlib import Path

# Pandoc 路径
PANDOC_PATH = r"C:\Users\KF\AppData\Local\Temp\pandoc\pandoc-3.2\pandoc.exe"

def convert_markdown_to_docx_with_pandoc_template(
    input_md: str,
    output_docx: str,
    template_docx: str,
    resource_path: str = None
):
    """
    使用 Pandoc 和模板文件将 Markdown 转换为 DOCX

    Args:
        input_md: 输入的 Markdown 文件路径
        output_docx: 输出的 DOCX 文件路径
        template_docx: 模板 DOCX 文件路径
        resource_path: 资源文件路径（可选，用于图片等）
    """

    # 检查输入文件
    if not os.path.exists(input_md):
        raise FileNotFoundError(f"输入文件不存在: {input_md}")

    if not os.path.exists(template_docx):
        raise FileNotFoundError(f"模板文件不存在: {template_docx}")

    # 确保输出目录存在
    output_dir = os.path.dirname(output_docx)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # 获取资源路径
    if resource_path is None:
        resource_path = os.path.dirname(os.path.abspath(input_md))

    # 构建 Pandoc 命令
    cmd = [
        PANDOC_PATH,
        input_md,
        "-o", output_docx,
        "--reference-doc=" + template_docx,
        "--resource-path=" + resource_path,
        "--standalone",
        "--toc",
        "--toc-depth=3",
        "--highlight-style=tango",
    ]

    print("执行 Pandoc 转换...")
    print(f"命令: {' '.join(cmd)}")
    print()

    # 执行 Pandoc
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )

        if result.stdout:
            print("Pandoc 输出:")
            print(result.stdout)

        print()
        print(f"✓ 转换成功！")
        print(f"输出文件: {output_docx}")

        # 验证输出文件
        if os.path.exists(output_docx):
            file_size = os.path.getsize(output_docx)
            print(f"文件大小: {file_size:,} 字节")
        else:
            print("⚠ 警告：输出文件未生成")

    except subprocess.CalledProcessError as e:
        print("✗ Pandoc 执行失败！")
        print(f"错误代码: {e.returncode}")
        print()
        print("错误输出:")
        print(e.stderr)
        raise

    return output_docx


def analyze_template_styles(template_docx: str):
    """
    分析模板样式
    """
    print("\n" + "="*60)
    print("模板样式分析")
    print("="*60 + "\n")

    try:
        from docx import Document

        doc = Document(template_docx)

        # 统计样式
        styles_used = set()
        for para in doc.paragraphs:
            styles_used.add(para.style.name)

        print(f"文档包含 {len(doc.styles)} 种样式")
        print(f"实际使用的样式: {len(styles_used)} 种")
        print()

        print("使用的样式列表:")
        for style in sorted(styles_used):
            print(f"  - {style}")

        # 检查关键样式
        print("\n关键样式检查:")
        for style_name in ['Heading 1', 'Heading 2', 'Normal', 'Title', 'Body Text']:
            if style_name in styles_used:
                print(f"  ✓ {style_name}")

    except Exception as e:
        print(f"分析失败: {e}")


if __name__ == '__main__':
    # 设置路径
    input_md = r'd:\projects\AI编程智驾\AI编程智驾手册.md'
    output_docx = r'd:\projects\AI编程智驾\AI编程智驾手册_模板版.docx'
    template_docx = r'd:\projects\AI编程智驾\标准文件.docx'

    print("="*60)
    print("Markdown 转 DOCX (Pandoc + 模板)")
    print("="*60)
    print()
    print(f"输入文件: {input_md}")
    print(f"模板文件: {template_docx}")
    print(f"输出文件: {output_docx}")
    print()

    # 分析模板
    analyze_template_styles(template_docx)

    # 执行转换
    try:
        result = convert_markdown_to_docx_with_pandoc_template(
            input_md=input_md,
            output_docx=output_docx,
            template_docx=template_docx
        )

        print()
        print("="*60)
        print("✓ 转换完成！")
        print("="*60)

    except Exception as e:
        print()
        print("="*60)
        print(f"✗ 转换失败: {e}")
        print("="*60)
        sys.exit(1)
