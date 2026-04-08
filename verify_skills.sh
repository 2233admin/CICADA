#!/bin/bash

echo "=== CICADA 技能验证脚本 ==="
echo ""

# 检查技能文件是否存在且不是占位符
skills=("code-review" "doc-gen" "test-helper" "git-helper" "refactor" "i18n")
all_valid=true

for skill in "${skills[@]}"; do
  file="assets/bundled_skills/$skill/skill.md"
  
  if [ ! -f "$file" ]; then
    echo "❌ $skill: 文件不存在"
    all_valid=false
    continue
  fi
  
  # 检查是否是占位符
  if grep -q "Bundled skill placeholder" "$file"; then
    echo "❌ $skill: 仍然是占位符"
    all_valid=false
    continue
  fi
  
  # 检查 YAML frontmatter
  if ! grep -q "^---$" "$file"; then
    echo "❌ $skill: 缺少 YAML frontmatter"
    all_valid=false
    continue
  fi
  
  # 检查必需字段
  if ! grep -q "^name:" "$file"; then
    echo "❌ $skill: 缺少 name 字段"
    all_valid=false
    continue
  fi
  
  if ! grep -q "^description:" "$file"; then
    echo "❌ $skill: 缺少 description 字段"
    all_valid=false
    continue
  fi
  
  # 检查 "When to Activate" 部分
  if ! grep -q "## When to Activate" "$file"; then
    echo "❌ $skill: 缺少 'When to Activate' 部分"
    all_valid=false
    continue
  fi
  
  echo "✅ $skill: 验证通过"
done

echo ""
echo "=== 验证 skill-sources.json ==="

if grep -q "clawhub.ai" "assets/presets/skill-sources.json"; then
  echo "❌ skill-sources.json 仍然包含 clawhub.ai 引用"
  all_valid=false
else
  echo "✅ skill-sources.json 已更新为纯本地模式"
fi

echo ""
echo "=== 验证 skills_page.dart ==="

if grep -qi "clawhub" "lib/pages/skills_page.dart"; then
  echo "❌ skills_page.dart 仍然包含 clawhub 引用"
  all_valid=false
else
  echo "✅ skills_page.dart 已移除所有 clawhub 引用"
fi

echo ""
if [ "$all_valid" = true ]; then
  echo "🎉 所有验证通过！CICADA 可以闭口了。"
  exit 0
else
  echo "⚠️  存在问题，请修复后再闭口。"
  exit 1
fi
