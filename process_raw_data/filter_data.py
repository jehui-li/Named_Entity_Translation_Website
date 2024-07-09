import re

# 删除（）以及（）内的东西
def remove_parentheses(text):
    pattern = re.compile(r'\([^()]*\)')
    result = re.sub(pattern, '', text)
    return result

# 删除（后的东西
def remove_after_parentheses(text):
    index = text.find('(')  # 查找第一个左括号的索引
    if index != -1:
        return text[:index]  # 截取左括号之前的内容
    else:
        return text

# 是否包含中文
def contains_chinese(text):
    pattern = re.compile(r'[\u4e00-\u9fa5]')  # 匹配中文字符的正则表达式模式
    result = re.search(pattern, text)
    return result is not None

# 是否全为英文
def is_english_sentence(text):
    pattern = re.compile(r'^[A-Za-z\s]+$')  # 匹配只包含英文字母和空格的正则表达式模式
    result = re.match(pattern, text)
    return result is not None


def filter_zh(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as file_in:
        with open(output_file, 'w', encoding='utf-8') as file_out:
            for line in file_in:
                line = line.split(' -> ')
                if contains_chinese(line[0]) is True or 'Alternative form of' in line[0] or is_english_sentence(line[1].strip()) is True or 'Used' in line[0] \
                    or '𫜸' in line[1] or 'Synonym' in line[0] or 'used' in line[0]:
                    continue
                else:
                    # file_out.write(line[0] + ' -> ' + line[1]) 
                    srcs = eval(line[0])[0].split('; ')
                    for src in srcs:
                        src = remove_parentheses(src)
                        src = remove_after_parentheses(src)
                        if src.strip() == '':
                            continue
                        else:
                            line[1] = remove_parentheses(line[1])
                            file_out.write(src.strip() + ' -> ' + line[1].strip() + '\n')
                    # file_out.write(eval(line[0])[0].replace('; ', '|') + ' -> ' + line[1]) 
in_path = r'D:\cache\fuwuqi_cache\data\extract_enwiktionary\kaikki.org-dictionary-Chinese.json.term.jianti'
out_path =  in_path + '.out_term'
filter_zh(in_path, out_path)