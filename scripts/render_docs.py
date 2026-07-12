from pathlib import Path
import re
import html
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Image, Table

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "pdf"
OUT.mkdir(parents=True, exist_ok=True)

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="Cover", parent=styles["Title"], fontName="Helvetica-Bold", fontSize=30, leading=35, textColor=colors.HexColor("#123A32"), alignment=TA_CENTER, spaceAfter=16))
styles.add(ParagraphStyle(name="Sub", parent=styles["Normal"], fontSize=12, leading=18, textColor=colors.HexColor("#4E645E"), alignment=TA_CENTER))
styles["Heading1"].textColor = colors.HexColor("#123A32")
styles["Heading2"].textColor = colors.HexColor("#246B5C")
styles["BodyText"].leading = 15
styles["BodyText"].spaceAfter = 7

def clean(text):
    text = html.escape(text)
    text = re.sub(r"`([^`]+)`", r"<font name='Courier'>\1</font>", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"\[([^]]+)\]\(([^)]+)\)", r"<u>\1</u>", text)
    return text

def build(source, target, title, subtitle):
    story = [Spacer(1, 42*mm), Paragraph(title, styles["Cover"]), Paragraph(subtitle, styles["Sub"]), Spacer(1, 18*mm), Paragraph("Rajveer Singh Jolly", styles["Sub"]), Paragraph("African Leadership University · Mobile Application Development", styles["Sub"]), PageBreak()]
    in_code = False
    code = []
    for raw in source.read_text().splitlines():
        line = raw.strip()
        if line.startswith("```"):
            if in_code and code:
                story.append(Paragraph(clean("<br/>".join(code)), styles["Code"]))
                code = []
            in_code = not in_code
            continue
        if in_code:
            code.append(raw.replace(" ", "&nbsp;"))
        elif line.startswith("# "):
            story.append(Paragraph(clean(line[2:]), styles["Heading1"]))
        elif line.startswith("## "):
            story.append(Paragraph(clean(line[3:]), styles["Heading1"]))
        elif line.startswith("### "):
            story.append(Paragraph(clean(line[4:]), styles["Heading2"]))
        elif line.startswith(("- ", "* ")):
            story.append(Paragraph("• " + clean(line[2:]), styles["BodyText"]))
        elif re.match(r"^\d+\. ", line):
            story.append(Paragraph(clean(line), styles["BodyText"]))
        elif line.startswith("|---") or line.startswith("| ---"):
            continue
        elif line.startswith("|"):
            story.append(Paragraph(clean(line.strip("|").replace("|", " · ")), styles["BodyText"]))
        elif line:
            story.append(Paragraph(clean(line), styles["BodyText"]))
        else:
            story.append(Spacer(1, 3*mm))
    if title == "Unfold":
        story.extend([
            PageBreak(),
            Paragraph("Application screenshots", styles["Heading1"]),
            Paragraph("Final release-mode discovery feed and opportunity detail workflow.", styles["BodyText"]),
            Spacer(1, 4*mm),
            Table([[
                Image(str(ROOT/"docs"/"screenshots"/"final-home.png"), width=75*mm, height=163*mm),
                Image(str(ROOT/"docs"/"screenshots"/"final-profile.png"), width=75*mm, height=163*mm),
            ]], colWidths=[78*mm, 78*mm]),
        ])
    doc = SimpleDocTemplate(str(target), pagesize=A4, rightMargin=18*mm, leftMargin=18*mm, topMargin=17*mm, bottomMargin=17*mm, title=title, author="Rajveer Singh Jolly")
    doc.build(story)

build(ROOT/"docs"/"TECHNICAL_REPORT.md", OUT/"RajveerSinghJolly_FinalFlutterProject.pdf", "Unfold", "Technical report · opportunity discovery for the ALU community")
build(ROOT/"docs"/"STUDY_GUIDE.md", OUT/"Unfold_Study_Guide.pdf", "Know Unfold", "A concise codebase and presentation study guide")
