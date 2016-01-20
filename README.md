README
===

## 使用场景

很多在美国的留学生为节省话费选择多人共享的合约，
如 AT&T 的 [Mobile Share Value Plans](https://www.att.com/shop/wireless/data-plans.html)、
T-Mobile 的 [Family Plan](http://www.t-mobile.com/cell-phone-plans.html)。
此类合约的费用主要包含：

1. 个人费用，包括每月月租，各项杂费、税费，以及流量超额的费用；
2. 公摊费用，即套餐的费用除以合约成员的人数。


本脚本针对 AT&T 用户，用于计算多人共享手机合约的话费，并且可以群发账单。

AT&T 账单的样板可参见[链接](https://www.att.com/Common/images/Consumer_Wireless_021711.pdf)。

### 计算方法

```
公摊费用 = (套餐的费用 - 折扣) / 人数
每个人缴纳的费用 = 个人费用 + 公摊费用
```

当使用的流量超额时，超额的费用由使用流量超过1GB的成员按照超出数量的比例支付。

## 邮件模版

`Message.html.erb` 是账单邮件的模版。

邮件模版使用 Embedded Ruby (ERB) Template。
具体语法可参见[链接](http://guides.rubyonrails.org/layouts_and_rendering.html)。

用户可以根据需要修改模版。

## 配置

`dat.yml` 是脚本的配置文件。配置文件中定义了合约的价格、合约成员的联系方式、邮箱服务器等。

配置文件的格式是 YAML。具体语法可参见[ YAML 官方页面](http://www.yaml.org/)。

### 修改合约

* `plan` 中可修改合约的费用和折扣。
* `contacts` 中可修改合约成员的姓名和联系方式。

### 配置邮箱

`mail_config` 中设置了邮箱服务器和账号。

参数含义可参见[ Pony 文档](https://github.com/benprew/pony)。

### 修改翻译

`translations` 中设置了名词的翻译。

## 使用

```
ruby accounting.rb
```

Dry-run 模式

```
ruby accounting.rb -d
```
