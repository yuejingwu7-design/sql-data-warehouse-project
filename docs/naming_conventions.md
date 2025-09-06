# 《项目名称规则》

## 总体规则

名称规则

利用蛇形取名规则, 即所有实体名称均小写，分隔符为“_”, 例如snake_case.

语言

取名均为英语

防止措施

禁止使用与SQL预留指令相同的名称，如select

## 各层取名规则

### 阶段层规则

- 所有名称必须以源系统名称开头，并且表名称必须和其原来的名称匹配，防止随意更改。
- <sourcesystem>_<entity>
    - <sourcesystem>: 源系统的名称（例如 crm, erp）
    - <entity>: 确定好的来自源系统的表名称
    - 案例：crm_customer_info → 来自CRM系统的客户信息

### 企业数仓层规则

- 所有名称必须以源系统名称开头，并且表名称必须和其原来的名称匹配，防止随意更改。
- <sourcesystem>_<entity>
    - <sourcesystem>: 源系统的名称（例如 crm, erp）
    - <entity>: 确定好的来自源系统的表名称
    - 案例：crm_customer_info → 来自CRM系统的客户信息

### 数据集市层规则

- 所有名称必须使用有意义的，和业务相关的表名称，以目录前缀作为开头。
- <category>_<entity>
    - <category>: 描述表的作用，比如dim(dimension:度量）、fact（事件）
    - <entity>: 描述性的表名称，和业务领域的意义一致，比如customers、products、sales
    - 案例：
        - dim_customers → 关于客户信息的度量表
        - fact_sales → 包含销售记录的事实表

### 目录取名模式

模式

dim_

fact_

agg_

### 列名称规则

意义

维度表

事实表

聚合表

案例

dim_customer, dim_product

fact_sales

agg_customers, agg_sales_monthly

代理键

- 所有维度表的主键必须使用后缀_key.
- <table_name>_key:
    - <table_name>: 指键所归属的表名或实体名
    - _key: 一个后缀，表明这一列是主键
    - 案例：customer_key → 在dim_customers表中的主键

技术列

- 所有的技术列必须使用前缀dwh_, 后以描述性名称表达该列的意义
- dwh_<column_name>:
    - dwh: 匹配于系统，或由系统生成的元数据前缀
    - <column_name>: 描述性名称，表达该列的意义
    - 案例：dwh_load_key → 系统生成的列，用于保存记录生成的日期

### 保存程序规范

- 所有用于加载数据的保存规范必须满足取名模式：load_<layer>.
    - <layer>: 表明被加载的层级，比如阶段层, 企业数仓层, 企业集市层。
    - 案例：
        - load_stage → 用于载入阶段层的保存程序
        - load_dwh → 用于载入企业数仓层的保存程序
