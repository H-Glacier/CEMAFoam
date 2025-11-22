#!/usr/bin/env python3
"""
诊断 PyJac 和 OpenFOAM 集成问题的脚本
"""

import os
import re
import sys

def check_reaction_file(filepath):
    """检查反应机理文件"""
    print(f"\n检查反应文件: {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ❌ 文件不存在")
        return
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # 提取元素和物种
    elements_match = re.search(r'elements\s+(\d+)', content)
    species_match = re.search(r'species\s+(\d+)', content)
    
    if elements_match:
        n_elements = int(elements_match.group(1))
        print(f"  ✓ 元素数量: {n_elements}")
    else:
        print(f"  ❌ 无法找到元素定义")
    
    if species_match:
        n_species = int(species_match.group(1))
        print(f"  ✓ 物种数量: {n_species}")
        
        # 提取物种列表
        species_pattern = r'species\s+\d+\s*\((.*?)\);'
        species_list_match = re.search(species_pattern, content, re.DOTALL)
        if species_list_match:
            species_text = species_list_match.group(1)
            species_list = re.findall(r'(\w+)', species_text)
            print(f"  ✓ 物种列表前10个: {species_list[:10]}")
    else:
        print(f"  ❌ 无法找到物种定义")

def check_thermo_file(filepath):
    """检查热物理属性文件"""
    print(f"\n检查热物理属性文件: {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ❌ 文件不存在")
        return
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # 统计物种数量
    species_pattern = r'^([A-Z][A-Za-z0-9\(\)]*)\s*\{'
    species_matches = re.findall(species_pattern, content, re.MULTILINE)
    
    print(f"  ✓ 定义的物种数量: {len(species_matches)}")
    print(f"  ✓ 物种列表前10个: {species_matches[:10]}")
    
    # 检查每个物种是否有必要的属性
    missing_transport = []
    missing_elements = []
    
    for species in species_matches:
        species_block_pattern = f'{re.escape(species)}\\s*{{(.*?)^}}'
        species_block = re.search(species_block_pattern, content, re.MULTILINE | re.DOTALL)
        if species_block:
            block_content = species_block.group(1)
            if 'transport' not in block_content:
                missing_transport.append(species)
            if 'elements' not in block_content:
                missing_elements.append(species)
    
    if missing_transport:
        print(f"  ⚠ {len(missing_transport)} 个物种缺少输运属性: {missing_transport[:5]}")
    else:
        print(f"  ✓ 所有物种都有输运属性")
    
    if missing_elements:
        print(f"  ⚠ {len(missing_elements)} 个物种缺少元素定义: {missing_elements[:5]}")
    else:
        print(f"  ✓ 所有物种都有元素定义")

def check_pyjac_headers():
    """检查 PyJac 头文件"""
    print(f"\n检查 PyJac 头文件:")
    
    pyjac_dir = "/workspace/src/thermophysicalModels/chemistryModel/pyjacInclude"
    
    if not os.path.exists(pyjac_dir):
        print(f"  ❌ PyJac 包含目录不存在: {pyjac_dir}")
        return
    
    required_headers = ['chem_utils.h', 'dydt.h', 'jacob.h', 'mechanism.h']
    
    for header in required_headers:
        header_path = os.path.join(pyjac_dir, header)
        if os.path.exists(header_path):
            print(f"  ✓ {header} 存在")
            
            # 检查 mechanism.h 中的物种数量
            if header == 'mechanism.h':
                with open(header_path, 'r') as f:
                    content = f.read()
                    nsp_match = re.search(r'#define\s+NSP\s+(\d+)', content)
                    if nsp_match:
                        print(f"    PyJac NSP (物种数): {nsp_match.group(1)}")
        else:
            print(f"  ❌ {header} 不存在")

def main():
    print("=" * 60)
    print("PyJac-OpenFOAM 集成诊断工具")
    print("=" * 60)
    
    # 检查关键文件
    tutorial_dir = "/workspace/tutorials/premixedFlame1D/constant"
    
    check_reaction_file(os.path.join(tutorial_dir, "reactionsGRIPyjac"))
    check_thermo_file(os.path.join(tutorial_dir, "thermo.compressibleGasGRI"))
    check_pyjac_headers()
    
    print("\n" + "=" * 60)
    print("诊断建议:")
    print("=" * 60)
    print("""
1. 确保 PyJac 生成的机理与 OpenFOAM 配置一致：
   - 物种数量必须匹配
   - 元素数量必须匹配
   
2. 如果出现 Dimix 错误，尝试：
   - 修改 transport 类型为 'const' 或 'polynomial'
   - 确保所有物种都有完整的输运属性
   
3. 重新生成 PyJac 文件：
   cd /workspace/tutorials/premixedFlame1D/mechanism
   ./runCmake.sh
   
4. 检查环境变量：
   echo $FOAM_USER_LIBBIN
   ls -la $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel*
    """)

if __name__ == "__main__":
    main()