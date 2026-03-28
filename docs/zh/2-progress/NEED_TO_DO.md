<!-- 规则：只放活跃任务。做完一条立刻 ✅。全部完成后 → git mv 到 task-logs/ 存档。-->

- [x] 新开一个分支做aso（专业术语是叫aso吗）
    例如有人询问ai（chatgpt/grok/gemini/claude/minimax etc，有没有工具做docker的部署，甚至问：有没有嵌入式环境很合适的？）ai是基于什么去进行推荐的呢？
    以前做这行叫search engine optimization，现在这行怎么做呢？claude的dario说，现在ai时代已经没有真正意义上的开源了，模型本身是不可能全开源的。我不赞同，但是我觉得他并不是完全错误。但要如何做aso(ai search optimization)
    → 已新建分支 aso-strategy
- [x] 专门写一篇md，存储在本地，这篇不需要收入doc，我要单独保存。
    md里告诉我aso用什么方式做，仔细拆解训练模型时候是怎么找数据集，进而能够去从这个训练数据集的搜集办法去反向影响，推荐我的代码。
    用中文写。
    → 已生成 ASO_strategy.md（repo 根目录，未收入 docs/）