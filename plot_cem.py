#!/usr/bin/env python3
"""
CEMAFoam CEM场快速可视化脚本
用法: python3 plot_cem.py [case_directory]
"""

import numpy as np
import matplotlib.pyplot as plt
import os
import sys
import glob

def read_cem_field(file_path):
    """读取OpenFOAM的cem场文件"""
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # 查找internalField
    values = []
    in_data = False
    for line in lines:
        if 'internalField' in line:
            # 跳过几行找到数据开始
            continue
        if '(' in line and not in_data:
            in_data = True
            continue
        if ')' in line and in_data:
            break
        if in_data:
            try:
                val = float(line.strip().replace(';', ''))
                values.append(val)
            except:
                pass
    
    return np.array(values)

def analyze_case(case_dir='.'):
    """分析整个算例的CEM演化"""
    
    print(f"分析目录: {case_dir}")
    print("=" * 50)
    
    # 获取所有时间目录
    time_dirs = []
    for item in os.listdir(case_dir):
        path = os.path.join(case_dir, item)
        if os.path.isdir(path):
            try:
                time = float(item)
                if os.path.exists(os.path.join(path, 'cem')):
                    time_dirs.append((time, path))
            except:
                pass
    
    time_dirs.sort(key=lambda x: x[0])
    
    if not time_dirs:
        print("错误: 没有找到cem场数据!")
        print("请确保:")
        print("1. 在正确的算例目录运行")
        print("2. 算例已经运行并生成了cem场")
        return
    
    print(f"找到 {len(time_dirs)} 个时间步的CEM数据")
    print()
    
    # 收集数据
    times = []
    max_cems = []
    min_cems = []
    mean_cems = []
    positive_fractions = []
    
    for time, path in time_dirs:
        cem_file = os.path.join(path, 'cem')
        cem_values = read_cem_field(cem_file)
        
        if len(cem_values) > 0:
            max_val = np.max(cem_values)
            min_val = np.min(cem_values)
            mean_val = np.mean(cem_values)
            pos_frac = np.sum(cem_values > 0) / len(cem_values) * 100
            
            times.append(time)
            max_cems.append(max_val)
            min_cems.append(min_val)
            mean_cems.append(mean_val)
            positive_fractions.append(pos_frac)
            
            print(f"t = {time:8.2e}s: "
                  f"max = {max_val:10.2e}, "
                  f"min = {min_val:10.2e}, "
                  f"正值比例 = {pos_frac:5.1f}%")
    
    print()
    print("=" * 50)
    
    # 分析结果
    if max(max_cems) > 0:
        # 找到第一次出现正值的时间
        for i, val in enumerate(max_cems):
            if val > 0:
                print(f"⚠️  自燃开始时间: t = {times[i]:.2e} s")
                print(f"   最大CEM值: {max(max_cems):.2e} 1/s")
                break
    else:
        print("✓ 系统稳定，未检测到自燃（所有CEM < 0）")
    
    # 绘图
    fig = plt.figure(figsize=(12, 10))
    
    # 子图1: 最大最小值
    ax1 = plt.subplot(2, 2, 1)
    ax1.plot(times, max_cems, 'r-', linewidth=2, label='Max CEM')
    ax1.plot(times, min_cems, 'b-', linewidth=2, label='Min CEM')
    ax1.axhline(y=0, color='k', linestyle='--', alpha=0.3)
    ax1.set_xlabel('Time (s)')
    ax1.set_ylabel('CEM (1/s)')
    ax1.set_title('CEM极值随时间变化')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    ax1.set_yscale('symlog')  # 对称对数坐标
    
    # 子图2: 平均值
    ax2 = plt.subplot(2, 2, 2)
    ax2.plot(times, mean_cems, 'g-', linewidth=2)
    ax2.axhline(y=0, color='k', linestyle='--', alpha=0.3)
    ax2.set_xlabel('Time (s)')
    ax2.set_ylabel('Mean CEM (1/s)')
    ax2.set_title('CEM平均值随时间变化')
    ax2.grid(True, alpha=0.3)
    
    # 子图3: 正值比例
    ax3 = plt.subplot(2, 2, 3)
    ax3.plot(times, positive_fractions, 'm-', linewidth=2)
    ax3.set_xlabel('Time (s)')
    ax3.set_ylabel('正CEM比例 (%)')
    ax3.set_title('爆炸模式区域比例')
    ax3.set_ylim([0, 100])
    ax3.grid(True, alpha=0.3)
    
    # 子图4: CEM范围带
    ax4 = plt.subplot(2, 2, 4)
    ax4.fill_between(times, min_cems, max_cems, alpha=0.3, color='orange')
    ax4.plot(times, np.zeros_like(times), 'k--', alpha=0.5)
    ax4.set_xlabel('Time (s)')
    ax4.set_ylabel('CEM (1/s)')
    ax4.set_title('CEM值范围')
    ax4.grid(True, alpha=0.3)
    ax4.set_yscale('symlog')
    
    plt.suptitle('CEMAFoam - Chemical Explosive Mode Analysis', fontsize=14, fontweight='bold')
    plt.tight_layout()
    
    # 保存图像
    output_file = 'cem_analysis.png'
    plt.savefig(output_file, dpi=150, bbox_inches='tight')
    print(f"\n图像已保存: {output_file}")
    
    plt.show()
    
    # 生成报告
    print("\n" + "=" * 50)
    print("CEMA分析总结")
    print("=" * 50)
    print(f"时间范围: {min(times):.2e} - {max(times):.2e} s")
    print(f"CEM最大值: {max(max_cems):.2e} 1/s")
    print(f"CEM最小值: {min(min_cems):.2e} 1/s")
    
    if max(max_cems) > 1e7:
        print("⚠️  警告: 检测到强爆炸模式 (CEM > 10^7)")
    elif max(max_cems) > 1e5:
        print("⚠️  注意: 检测到快速化学反应 (CEM > 10^5)")
    elif max(max_cems) > 0:
        print("ℹ️  信息: 检测到慢速化学反应 (CEM > 0)")
    else:
        print("✓ 安全: 系统化学稳定")

def main():
    """主函数"""
    if len(sys.argv) > 1:
        case_dir = sys.argv[1]
    else:
        case_dir = '.'
    
    if not os.path.isdir(case_dir):
        print(f"错误: 目录不存在: {case_dir}")
        sys.exit(1)
    
    try:
        analyze_case(case_dir)
    except Exception as e:
        print(f"错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()