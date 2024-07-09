#!/bin/bash
# Adapted from https://github.com/facebookresearch/MIXER/blob/master/prepareData.sh

#克隆 Moses 仓库，其中包含用于标记化脚本的工具
echo 'Cloning Moses github repository (for tokenization scripts)...'

#git clone命令从GitHub上克隆"Moses"项目
git clone https://github.com/moses-smt/mosesdecoder.git

#克隆 Subword NMT 仓库，其中包含用于 BPE（字节对编码）预处理的工具
echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
git clone https://github.com/rsennrich/subword-nmt.git

#Moses 脚本的路径
SCRIPTS=mosesdecoder/scripts

#标记化脚本的路径，标记化是将句子拆分成单词或子词的过程
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl

#清理语料库的脚本的路径，清理语料库通常包括去除无效字符、去除重复行等操作
CLEAN=$SCRIPTS/training/clean-corpus-n.perl

#指定了标点符号规范化脚本的路径。它用于对标点符号进行规范化，将不同的引号、连字符等替换为统一的形式
NORM_PUNC=$SCRIPTS/tokenizer/normalize-punctuation.perl

#指定了去除非打印字符的脚本的路径。去除文本中的控制字符、特殊符号等。
REM_NON_PRINT_CHAR=$SCRIPTS/tokenizer/remove-non-printing-char.perl

#Subword NMT 工具的路径，Subword NMT用于处理词汇表中的稀有单词和未登录词
#"unidirectional"在训练数据中出现的频率较低。Subword NMT将这些单词切分为更小的子词"uni-directional"
BPEROOT=subword-nmt/subword_nmt

#BPE 编码器的标记数目为 40000，BPE是一种常用的子词分割方法，用于将词汇表中的单词切分成更小的子词单元。
BPE_TOKENS=40000

#要下载的文件的 URL，有不同的语料库和数据集
URLS=(
    "http://statmt.org/wmt13/training-parallel-europarl-v7.tgz"
    "http://statmt.org/wmt13/training-parallel-commoncrawl.tgz"
    "http://data.statmt.org/wmt17/translation-task/training-parallel-nc-v12.tgz"
    "http://data.statmt.org/wmt17/translation-task/dev.tgz"
    "http://statmt.org/wmt14/test-full.tgz"
)

#要下载的文件的名称,与之前的 URL 对应
FILES=(
    "training-parallel-europarl-v7.tgz"
    "training-parallel-commoncrawl.tgz"
    "training-parallel-nc-v12.tgz"
    "dev.tgz"
    "test-full.tgz"
)

#训练数据和开发数据的位置,用于下载和准备数据集。
CORPORA=(
    "training/europarl-v7.de-en"
    "commoncrawl.de-en"
    "training/news-commentary-v12.de-en"
)

# This will make the dataset compatible to the one used in "Convolutional Sequence to Sequence Learning"
# https://arxiv.org/abs/1705.03122

#检查变量 SCRIPTS 指定的路径是否存在
if [ ! -d "$SCRIPTS" ]; then

#如果指定的路径不存在，将输出错误消息并退出脚本
    echo "Please set SCRIPTS variable correctly to point to Moses scripts."
    exit
fi

#src 是源语言的标识符，英语
src=en

#tgt 是目标语言的标识符，德语
tgt=de

#lang 是源语言和目标语言的组合标识符
lang=en-de

#prep 是数据预处理的目录，如果使用了--icml17参数，则设置为wmt14_en_de，否则设置为wmt17_en_de
prep=$OUTDIR

#tmp 是临时目录，用于存储临时文件
tmp=$prep/tmp

#orig 是原始数据的目录
orig=orig

#dev 是开发集的目录
dev=dev/newstest2013

#递归创建了三个目录：$orig、$tmp 和 $prep
mkdir -p $orig $tmp $prep

#进入 $orig 目录
cd $orig

#遍历 URLS
for ((i=0;i<${#URLS[@]};++i)); do
    #对应索引位置的文件名
    file=${FILES[i]}

    #如果文件名已存在
    if [ -f $file ]; then

    #则输出一条消息表示文件已存在并跳过下载
        echo "$file already exists, skipping download"

    #如果文件不存在
    else
        url=${URLS[i]}

        #wget 命令下载对应的URL
        wget "$url"

        #检查下载是否成功
        if [ -f $file ]; then
            echo "$url successfully downloaded."
        else
            echo "$url not successfully downloaded."
            exit -1
        fi

        #根据文件的扩展名（.tgz 或 .tar）
        if [ ${file: -4} == ".tgz" ]; then

        #使用 tar 命令解压缩文件
            tar zxvf $file
        elif [ ${file: -4} == ".tar" ]; then
            tar xvf $file
        fi
    fi
done

#返回上一级目录
cd ..

#处理训练数据
echo "pre-processing train data..."
for l in $src $tgt; do
    #删除临时文件 $tmp/train.tags.$lang.tok.$l,lang:en-dn
    rm $tmp/train.tags.$lang.tok.$l

    #对于 $src 和 $tgt（源语言和目标语言），循环遍历 $CORPORA 数组中的元素。
    for f in "${CORPORA[@]}"; do
        # |表示将前一命令的输出作为后一命令输入 
        #  \行位续行符，一行命令多行书写
        cat $orig/$f.$l | \

            #对数据进行标点符号的规范化处理
            perl $NORM_PUNC $l | \

            #移除非打印字符
            perl $REM_NON_PRINT_CHAR | \

            #使用 tokenizer.perl 进行分词处理，并将处理后的结果追加到 $tmp/train.tags.$lang.tok.$l 文件中
            #‘-threads 8’ 8线程处理  ’-a‘将每个输入文本分割成多个句子  ’-l‘指定语言表示（en/de）
            perl $TOKENIZER -threads 8 -a -l $l >> $tmp/train.tags.$lang.tok.$l
    done
done

#对测试数据进行预处理
echo "pre-processing test data..."

#确定源语言和目标语言的文件后缀（$src 和 $tgt）
for l in $src $tgt; do
    if [ "$l" == "$src" ]; then
        t="src"
    else
        t="ref"
    fi

    # grep搜索，在$orig/test-full/newstest2014-deen-$t.$l.sgm 文件中搜索中包含 <seg id 的行
    grep '<seg id' $orig/test-full/newstest2014-deen-$t.$l.sgm | \

        # s/.../.../g，第一个省略号中的内容表示要替换的内容，后一个省略号中表示替换后的内容
        # \s*表示若干空白符，以\\g结尾表示替换为空白符，g代表全局替换
        # 将<seg id="[0-9]*">以及其后的若干空白符全部替换为空白，即删除
        sed -e 's/<seg id="[0-9]*">\s*//g' | \

        # 将</seg>以及前后若干空白符全部替换为空白 即删除，<\/seg>中的\为转义符
        sed -e 's/\s*<\/seg>\s*//g' | \

        # 将’替换为’
        sed -e "s/\’/\'/g" | \

    #对处理后的数据进行分词，并将结果保存到 $tmp/test.$l 文件中
    perl $TOKENIZER -threads 8 -a -l $l > $tmp/test.$l
    echo ""
done

echo "splitting train and valid..."

# 划分训练和验证， NR为当前文件中正在处理的行数，即每隔一百行选取一行将其保存到valid路径下
for l in $src $tgt; do
    awk '{if (NR%100 == 0)  print $0; }' $tmp/train.tags.$lang.tok.$l > $tmp/valid.$l
    awk '{if (NR%100 != 0)  print $0; }' $tmp/train.tags.$lang.tok.$l > $tmp/train.$l
done

# 将"$tmp/train.de-en"的路径赋值给TRAIN
TRAIN=$tmp/train.de-en

# 设置 BPE 代码文件的路径
BPE_CODE=$prep/code

# 删除已存在的 $TRAIN 文件（如果存在）
rm -f $TRAIN

# 将源语言和目标语言的训练数据合并到 $TRAIN 文件中
for l in $src $tgt; do
    cat $tmp/train.$l >> $TRAIN
done

# 输出学习 BPE 的提示信息
echo "learn_bpe.py on ${TRAIN}..."

# 运行 learn_bpe.py 脚本，基于 $TRAIN 文件学习 BPE，将结果保存到 $BPE_CODE 文件中
python $BPEROOT/learn_bpe.py -s $BPE_TOKENS < $TRAIN > $BPE_CODE

for L in $src $tgt; do
    for f in train.$L valid.$L test.$L; do

         # 输出应用 BPE 的提示信息
        echo "apply_bpe.py to ${f}..."

         # 运行 apply_bpe.py 脚本，使用 $BPE_CODE 对输入文件 $tmp/$f 进行 BPE 处理，并将结果保存到 $tmp/bpe.$f 文件中
        python $BPEROOT/apply_bpe.py -c $BPE_CODE < $tmp/$f > $tmp/bpe.$f
    done
done

# 运行 perl 脚本 $CLEAN，使用参数对 $tmp/bpe.train 文件进行数据清理，并将清理后的结果保存到 $prep/train 文件中
perl $CLEAN -ratio 1.5 $tmp/bpe.train $src $tgt $prep/train 1 250

# 运行 perl 脚本 $CLEAN，使用参数对 $tmp/bpe.valid 文件进行数据清理，并将清理后的结果保存到 $prep/valid 文件中
perl $CLEAN -ratio 1.5 $tmp/bpe.valid $src $tgt $prep/valid 1 250

# 复制 $tmp/bpe.test.$L 文件到 $prep/test.$L，即将处理后的测试集文件复制到目标目录中
for L in $src $tgt; do
    cp $tmp/bpe.test.$L $prep/test.$L
done