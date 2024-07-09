import json

lst = []
with open("kaikki.org-dictionary-Chinese.json", encoding="utf-8") as f:
    for line in f:
        # 解析词典数据
        data = json.loads(line)
        lst.append(data)
        # 提取中文和英文
        chinese_word = data["word"]
        if "senses" in data:
            sense = data["senses"][0]
            if "glosses" in sense:
                english_word = data["senses"][0]["glosses"]
                # 保存中文和英文到文件
                # with open("ch-en.txt", "w", encoding="utf-8") as file:
                #     for gloss in english_word:
                #         file.write(gloss + "\n")
                #         file.close()
            elif "raw_glosses" in sense:
                english_word = data["senses"][0]["raw_glosses"]
                # 保存中文和英文到文件
                # with open("ch-en.txt", "w", encoding="utf-8") as file:
                #     for gloss in english_word:
                #         file.write(gloss + "\n")
                #         file.close()

            # else:
            #     english_word = []
            # if data["senses"][0]["glosses"] in data:
        #     english_word = data["senses"][0]["glosses"]
        # else:
        #     sense = data["senses"][2]
        #     english_word = sense["raw_glosses"]

        # 去除英文开头的"['"和结尾的"']"
        english_word = str(english_word).replace(".jpg", "").replace("'", "").replace("[","").replace("]", "").replace("\"", "")
        # english_word = english_word.strip("['']").strip()
        # english_word = english_word[1:-1]

        # 保存中文和英文到文件
        with open("ch-en.txt", "a", encoding="utf-8") as file:
            file.write(f"{chinese_word}\t->\t{english_word}\n")
            # file.write(f"{chinese_word} {english_word}\n")

        # 打印中文和英文
        print(f"中文：{chinese_word}，英文：{english_word}")

        # 打印此行的信息
        # print(json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False))





