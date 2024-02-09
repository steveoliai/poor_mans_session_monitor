
select table_name,constraint_name,cons_columns from (
select table_name,constraint_name,rtrim(xmlagg(xmlelement(e,column_name||',').extract('//text()')),',')cons_columns from (
select c1.table_name,c1.constraint_name,c2.column_name,c2.position from all_constraints c1 , all_cons_columns c2
where c1.constraint_name=c2.constraint_name    
and c1.owner=c2.owner
and c1.owner='ULSPRODEMK'
and c1.constraint_type='R'
and c1.status='ENABLED'  
order by 1,2,4)
group by table_name,constraint_name)x1
where not exists (select 1 from (
select table_name,index_name,rtrim(xmlagg(xmlelement(e,column_name||',').extract('//text()')),',')ind_columns from (
select i1.table_name,i1.index_name,i2.column_name,i2.column_position from all_indexes i1,all_ind_columns i2
where  i1.owner=i2.index_owner
and i1.index_name=i2.index_name
and i1.owner='ULSPRODEMK'  
order by 1,2,4)
group by table_name,index_name)x2
where x2.table_name=x1.table_name and INSTR(x2.ind_columns,x1.cons_columns,1,1)<>0 );