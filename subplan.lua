-- Copyright (C) 2006-2018 Alexey Kopytov <akopytov@gmail.com>

-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

-- Common code for OLTP benchmarks.

function init() 
    assert(event ~= nil,
        "this script is meant to be included by other OLTP scripts and " .. 
        "should not be called directly.")
end

if sysbench.cmdline.command == nil then
    error("Command is required. Supported commands: prepare, prewarm, run, " .. 
            "cleanup, help")
end

-- Command line options 
sysbench.cmdline.options = {
    table_size =
        {"Number of rows per table", 10000}, 
    range_size =
        {"Range size for range SELECT queries", 100}, 
    tables =
        {"Number of tables", 1}, 
    point_selects =
        {"Number of point SELECT queries per transaction", 10}, 
    simple_ranges =
        {"Number of simple range SELECT queries per transaction", 1}, 
    sum_ranges =
        {"Number of SELECT SUM() queries per transaction", 1}, 
    order_ranges =
        {"Number of SELECT ORDER BY queries per transaction", 1}, 
    distinct_ranges =
        {"Number of SELECT DISTINCT queries per transaction", 1}, 
    index_updates =
        {"Number of UPDATE index queries per transaction", 1}, 
    non_index_updates =
        {"Number of UPDATE non-index queries per transaction", 1}, 
    delete_inserts =
        {"Number of DELETE/INSERT combinations per transaction", 1}, 
    range_selects =
        {"Enable/disable all range SELECT queries", true}, 
    auto_inc =
        {"Use AUTO_INCREMENT column as Primary Key (for MySQL), " .. 
            "or its alternatives in other DBMS. When disabled, use " ..
            "client-generated IDs", false}, 
    skip_trx =
        {"Don't start explicit transactions and execute all queries " .. 
            "in the AUTOCOMMIT mode", false},
    secondary =
        {"Use a secondary index in place of the PRIMARY KEY", false}, 
    create_secondary =
        {"Create a secondary index in addition to the PRIMARY KEY", true}, 
    mysql_storage_engine =
        {"Storage engine, if MySQL is used", "innodb"}, 
    pgsql_variant =
        {"Use this PostgreSQL variant when running with the " .. 
            "PostgreSQL driver. The only currently supported " .. 
            "variant is 'redshift'. When enabled, " .. 
            "create_secondary is automatically disabled, and " .. 
            "delete_inserts is set to 0"}
}
    
    
-- Prepare the dataset. This command supports parallel execution, i.e. will
-- benefit from executing with --threads > 1 as long as --tables > 1 
function cmd_prepare()
    local drv = sysbench.sql.driver()
    local con = drv:connect() 
    if sysbench.tid == 1 then
        create_table(drv, con, 1) 
    elseif sysbench.tid == 2 then 
        create_table(drv, con, 2) 
        create_index(drv, con)
    end
end

-- Implement parallel prepare and prewarm commands 
sysbench.cmdline.commands = {
    prepare = {cmd_prepare, sysbench.cmdline.PARALLEL_COMMAND}
}

-- Template strings of random digits with 11-digit groups separated by dashes

-- 10 groups, 119 characters
local c_value_template = "###########-###########-###########-" .. 
    "###########-###########-###########-" ..
    "###########-###########-###########-" .. 
    "###########"

-- 5 groups, 59 characters
local pad_value_template = "###########-###########-###########-" ..
    "###########-###########"

function get_c_value()
    return sysbench.rand.string(c_value_template)
end

function get_pad_value()
    return sysbench.rand.string(pad_value_template) 
end

function create_table(drv, con, table_id) 
    local query
    
    print(string.format("Creating table 't%d'...", table_id))
    query = string.format([[CREATE TABLE t%d(c1 int primary key, c2 int, c3 int, v1 CHAR(60), v2 CHAR(60), v3 CHAR(60), v4 CHAR(60), v5 CHAR(60), v6 CHAR(60), v7 CHAR(60), v8 CHAR(60), v9 CHAR(60))]], table_id)
    con:query(query)
    
    if (sysbench.opt.table_size > 0) then 
        print(string.format("Inserting %d records into 't%d'",
            sysbench.opt.table_size, table_id))
        query = "INSERT INTO t" .. table_id .. "(c1, c2, c3, v1, v2, v3, v4, v5, v6, v7, v8, v9) VALUES"
        con:bulk_insert_init(query) 
        local i_val
        local c_val 
        local pad_val

        for j = 1, sysbench.opt.table_size do
            i_val = sysbench.rand.default(1, sysbench.opt.table_size) 
            c_val = get_c_value()
            pad_val = get_pad_value()
            query = string.format("(%d, %d, %d, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s')", j, j, i_val, pad_val, pad_val, pad_val, pad_val, pad_val, pad_val, pad_val, pad_val, pad_val)
            con:bulk_insert_next(query)
        end
        con:bulk_insert_done()
    end
end

function create_index(drv, con) 
    if drv:name() == "mysql" 
    then
        do_query(drv, con, "create index t2_i1 on t2(c2)") 
        do_query(drv, con, "create index t2_i2 on t2(c3)")
    else
        do_query(drv, con, "create index t2_i1 on t2(c2) local") 
        do_query(drv, con, "create index t2_i2 on t2(c3) local")
    end
end

function do_query(drv, con, q) 
    print(q)
    con:query(q)
end
    
function prepare_begin()
    stmt.begin = con:prepare("BEGIN")
end

function prepare_commit()
    stmt.commit = con:prepare("COMMIT")
end
 
function prepare_rollback()
    stmt.rollback = con:prepare("rollback")
end

function thread_init()
    drv = sysbench.sql.driver() 
    con = drv:connect() 
end

function thread_done()
    --close_statements() 
    con:disconnect()
end
    
function cleanup()
    local drv = sysbench.sql.driver() 
    local con = drv:connect()
    
    for i = 1, 3 do
        print(string.format("Dropping table 't%d'...", i))
        con:query("DROP TABLE IF EXISTS t" .. i )
    end
end
    
    
local function get_table_num()
    return sysbench.rand.uniform(1, sysbench.opt.tables)
end

local function get_id()
    return sysbench.rand.default(1, sysbench.opt.table_size)
end
    
function begin() 
    stmt.begin:execute()
end

function commit() 
    stmt.commit:execute()
end

function rollback() 
    stmt.rollback:execute()
end

-- Re-prepare statements if we have reconnected, which is possible when some of
-- the listed error codes are in the --mysql-ignore-errors list 
function sysbench.hooks.before_restart_event(errdesc)
    if errdesc.sql_errno == 2013 or -- CR_SERVER_LOST 
        errdesc.sql_errno == 2055 or -- CR_SERVER_LOST_EXTENDED 
        errdesc.sql_errno == 2006 or -- CR_SERVER_GONE_ERROR 
        errdesc.sql_errno == 2011	-- CR_TCP_CONNECTION
    then
        close_statements() 
        prepare_statements()
    end
end

function event(thread_id) 
    local query
    --db_query("select /*+ordered use_nl(A,B)*/ count(*) from t1 A, t2 B where A.c1 = B.c1 and A.c2= B.c2")
    --db_query("select /*+ordered use_nl(A,B)*/ count(*) from t1 A, t2 B where A.c1 = B.c1")
    --db_query("select /*+ordered use_nl(A,B)*/ count(*) from t1 A, t2 B where A.c1 = B.c1 and A.c2= B.c2")
    --db_query("select /*+ordered use_nl(A,B)*/ * from t1 A, v6 B where A.c1 = B.c1")
    --db_query("select /*+ordered use_nl(A,B)*/ * from t1 A, v10 B where A.c1 = B.c2 and A.c3 = B.c3")
    ival = sysbench.rand.default(1, sysbench.opt.table_size) 
    left_min = ival - 100;
    left_max = ival + 100;
    cond = string.format("A.c1 >= %d and A.c1 < %d and A.c2 = B.c2 and A.c3 = B.c3", left_min, left_max)
    query = "select /*+ordered use_nl(A,B)*/ * from t1 A, t2 B where " .. cond
    con:query(query) 
end