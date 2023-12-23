# Other-MySQLCluster

```
```

## 目錄

- [Other-MySQLCluster](#other-mysqlcluster)
	- [目錄](#目錄)
	- [參考資料](#參考資料)
- [結構圖](#結構圖)
- [指令](#指令)
	- [init.sql](#initsql)
	- [mysql-cluster-shell](#mysql-cluster-shell)

## 參考資料

[MySQL 筆記](https://github.com/open222333/Other-Note/blob/8c0be0052b79a7782370c2af1b0a4a05943ef53c/03_%E4%BC%BA%E6%9C%8D%E5%99%A8%E6%9C%8D%E5%8B%99/DatabaseServer(%E8%B3%87%E6%96%99%E5%BA%AB%E4%BC%BA%E6%9C%8D%E5%99%A8)/MySQL/MySQL%20%E7%AD%86%E8%A8%98.md)

# 結構圖

```
port 以及 server-id

router_node_a1: 3306, 6346, 6347
node_a1: 1106, server-id=11
phpmyadmin_a1: 21111
node_a2: 1206, server-id=12
phpmyadmin_a2: 21112
phpmyadmin_router_a1_rw: 31001
phpmyadmin_router_a1_ro: 31002

router_node_b1: 3306, 6346, 6347
node_b1: 2106, server-id=21
phpmyadmin_b1: 22111
node_b2: 2206, server-id=22
phpmyadmin_b2: 22112
phpmyadmin_router_a2_rw: 32001
phpmyadmin_router_a2_ro: 32002
```

# 指令

## init.sql

```sql
-- SET GLOBAL validate_password_policy=0;
-- SET GLOBAL validate_password_length=4;
-- SET GLOBAL validate_password_special_char_count =0;
-- FLUSH PRIVILEGES;

-- 停止將 SQL 語句寫入二進制日誌
SET SQL_LOG_BIN=0;

UPDATE mysql.user SET host = '%' WHERE user = 'root';
SET PASSWORD FOR root@'%' = PASSWORD('root');
-- CREATE USER 'username'@'hostname' IDENTIFIED BY 'password';

-- 停止將 SQL 語句寫入二進制日誌
SET SQL_LOG_BIN=0;
-- 創建用於複製的用戶
-- CREATE USER rpl_user@'%': 這部分指定了要創建的使用者名稱和允許連接的主機或 IP 地址。
-- rpl_user 是使用者名稱，'%' 表示允許從任何主機或 IP 地址連接。
-- IDENTIFIED WITH 'mysql_native_password': 這是指定該使用者的身份驗證方法。在這種情況下，使用的是 MySQL 本地密碼（'mysql_native_password'）。
-- 這是一種常見的身份驗證方法，用於使用使用者名稱和密碼進行身份驗證。
-- BY 'password': 這是指定使用者的密碼。在這個示例中，密碼是 'password'。
CREATE USER rpl_user@'%' IDENTIFIED WITH 'mysql_native_password' BY 'root';
UPDATE mysql.user SET host = '%' WHERE user = 'rpl_user';
-- 為複製用戶授予 REPLICATION SLAVE 權限
GRANT REPLICATION SLAVE ON *.* TO rpl_user@'%';

CREATE USER 'innodbAdmin'@'%' IDENTIFIED by 'dWUYSCWpyx';
GRANT ALL PRIVILEGES ON *.* TO  'innodbAdmin'@'%' WITH GRANT OPTION;

CREATE USER 'mysqlsh.test'@'%' IDENTIFIED by 'dWUYSCWpyx';
GRANT REPLICATION SLAVE ON *.* TO  'mysqlsh.test'@'%' WITH GRANT OPTION;
-- 刷新權限
FLUSH PRIVILEGES;

-- 恢復將 SQL 語句寫入二進制日誌
SET SQL_LOG_BIN=1;
-- 安裝 Group Replication 插件
-- INSTALL PLUGIN group_replication SONAME 'group_replication.so';
-- 查看已安裝的插件
-- SHOW PLUGINS;
-- 設置複製主機的使用者名稱和密碼
-- CHANGE MASTER TO MASTER_USER='rpl_user', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery';
FLUSH PRIVILEGES;
```

## mysql-cluster-shell

```JavaScript
// https://dev.mysql.com/doc/dev/mysqlsh-api-javascript/8.0/group___admin_a_p_i.html

// 通過 shell 連接 mysql
shell.connect('root@127.0.0.1:3306')
shell.connect('root@192.168.154.112:1106')
shell.connect('root@192.168.154.112:1206')
shell.connect('root@192.168.158.173:2106')
shell.connect('root@192.168.158.173:2206')

// \sql
// RESET MASTER;

// 檢查實例配置，此處根據報錯修改配置文件，修改後需要重啟 MySQL(檢查正常會回傳 status:ok, 非必要)
dba.checkInstanceConfiguration('root@192.168.154.112:1106')
dba.checkInstanceConfiguration('root@192.168.154.112:1206')
dba.checkInstanceConfiguration('root@192.168.158.173:2106')
dba.checkInstanceConfiguration('root@192.168.158.173:2206')

// \disconnect  //退出連接
// 自動設置 Group Replication： 如果當前實例還沒有啟用 Group Replication，函數將自動執行必要的步驟來啟用 Group Replication。
// 自動加入 InnoDB Cluster： 如果當前實例是 InnoDB Cluster 的一部分，函數將自動將實例加入到 InnoDB Cluster 中。
// 配置和驗證參數： 函數將根據配置文件和集群設置來配置和驗證實例的參數，以確保其與其他實例保持一致。
// 持久化到配置⽂件中 (此功能僅適用於本地實例)
// 這個功能只能在本地的 MySQL 實例上使用，無法用於遠程的 MySQL 實例。
// 在這個上下文中， "本地實例" 指的是執行 MySQL Shell 的計算機上的 MySQL 伺服器。
dba.configureLocalInstance()

// 根據下面提示輸入 my.cnf 到完整路徑
// Please specify the path to the MySQL configuration file: /etc/my.cnf

// 選定一台
// 創建集群
// host mode 必須讓 container 可以取得 host 機器的 public ip、private ip 網卡
dba.createCluster('avnight')
dba.createCluster('avnight', {localAddress:'192.168.154.112:33061',ipAllowlist:'192.168.0.0/16,172.104.191.195,139.144.119.64'})

// 加入集群
// 出現錯誤則 到錯誤的節點進入mysql 使用 reset master;
var cluster = dba.getCluster('avnight')
dba.getCluster('avnight').addInstance('root@192.168.154.112:1106')
dba.getCluster('avnight').addInstance('root@192.168.154.112:1206')
dba.getCluster('avnight').addInstance('root@192.168.158.173:2106')
dba.getCluster('avnight').addInstance('root@192.168.158.173:2206')

// 移除節點
dba.getCluster('avnight').removeInstance('root@192.168.154.112:1206', {force:true})

// 查看集群狀態
dba.getCluster('avnight').status()
// 查看集群選項
dba.getCluster('avnight').options()


// https://ost.51cto.com/posts/16247
// select attributes->'$.group_replication_group_name' from mysql_innodb_cluster_metadata.clusters;
// +----------------------------------------------+
// | attributes->'$.group_replication_group_name' |
// +----------------------------------------------+
// | "bc664a9b-9b5b-11ec-8a73-525400c5601a"       |
// +----------------------------------------------+
// set global group_replication_group_name = "bc664a9b-9b5b-11ec-8a73-525400c5601a";
// set global group_replication_group_name = "";
// 重啟 Cluster
// https://dev.mysql.com/doc/dev/mysqlsh-api-javascript/8.0/classmysqlsh_1_1dba_1_1_dba.html#ac68556e9a8e909423baa47dc3b42aadb
dba.rebootClusterFromCompleteOutage()
dba.rebootClusterFromCompleteOutage('avnight', {primary:'node_1:3306', force:true})

// 重新掃描集群以查找新的和過時的組複製成員/實例，以及所使用的拓撲模式（即單主和多主）的更改。
dba.getCluster('avnight').rescan()
// 重新加入
dba.getCluster('avnight').rejoinInstance('root@192.168.154.112:1106')
dba.getCluster('avnight').rejoinInstance('root@192.168.154.112:1206')
// 解散集群 (無法訪問集群成員)
dba.getCluster('avnight').dissolve({force:true})

dba.getCluster('avnight').setPrimaryInstance('root@192.168.154.112:1106')

// 檢視路由資訊：listRouters()
dba.getCluster('avnight').listRouters()
```