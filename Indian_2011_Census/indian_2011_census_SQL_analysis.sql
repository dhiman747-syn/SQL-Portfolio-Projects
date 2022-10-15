/* 
	
    2011 Indian Census data
	--> Data analysis has been done for comparing the population figures of different states and districts.
    --> Assam has been compared with other Indian states and more prominently with other North Eastern States.
    
*/


-- see all the data of the two tables
select * from dataset1;
select * from dataset2_new;


-- check the number of records (rows) of the dataset1
select count(*) as num_of_rows
from dataset1;


-- check the number of records (rows) of the dataset2
select count(*) as num_of_rows
from dataset2_new;


-- check the number of fields (colunms) of the dataset1
select count(*) as num_of_columns
from information_schema.columns
where table_schema = 'indian_2011_census' and table_name = 'dataset1';


-- check the number of fields (colunms) of the dataset2
select count(*) as num_of_columns
from information_schema.columns
where table_schema = 'indian_2011_census' and table_name = 'dataset2_new';


-- getting info for state 'Assam'
select * from dataset1
where State = 'Assam'
order by District;


-- ranking the districts of Assam based on their sex ratio from highest to lowest
select 
	District,
    State,
    Growth,
    Literacy,
    Sex_Ratio, dense_rank() over(order by Sex_Ratio desc) as rank_sex_ratio
from dataset1
where State = 'Assam';


-- get the district(s) having the highest sex ratio for the state Assam
with cte as
(select 
	District,
    State,
    Sex_Ratio, dense_rank() over(order by Sex_Ratio desc) as rank_sex_ratio
from dataset1
where State = 'Assam') 
select 
	District as district_with_highest_sex_ratio,
    Sex_Ratio
from cte
where rank_sex_ratio = 1;


-- get the district(s) having the lowest sex ratio for the state Assam
with cte as
(select 
	District,
    State,
    Sex_Ratio, dense_rank() over(order by Sex_Ratio desc) as rank_sex_ratio
from dataset1
where State = 'Assam') 
select 
	District as district_with_lowest_sex_ratio,
    Sex_Ratio
from cte
where rank_sex_ratio = (select max(rank_sex_ratio) from cte);


-- top 5 districts of Assam with high sex ratio
select 
	District,
    State,
    Sex_Ratio,
    dense_rank() over(order by Sex_Ratio desc) as rank_sex_ratio
from dataset1
where State = 'Assam'
limit 5;


-- bottom 5 districts of Assam with very low sex ratio
select 
	District,
    State,
    Sex_Ratio,
    dense_rank() over(order by Sex_Ratio desc) as rank_sex_ratio
from dataset1
where State = 'Assam'
order by rank_sex_ratio desc
limit 5;


-- ranking the districts of Assam based on their literacy rate from highest to lowest
select
	District,
    State,
    Literacy, dense_rank() over(order by Literacy desc) as rank_literacy_rates
from dataset1
where State = 'Assam';


-- get the district(s) of Assam with the highest literacy rate
with lit_rates as
(select 
	District,
    State,
    Literacy, dense_rank() over(order by Literacy desc) as rank_literacy_rates
from dataset1
where State = 'Assam') 
select 
	District as district_with_highest_literacy_rate,
    Literacy
from lit_rates
where rank_literacy_rates = 1;


-- get the district(s) of Assam with the lowest literacy rate
with lit_rates as
(select 
	District,
    State,
    Literacy, dense_rank() over(order by Literacy desc) as rank_literacy_rates
from dataset1
where State = 'Assam') 
select 
	District as district_with_lowest_literacy_rate,
    Literacy
from lit_rates
where rank_literacy_rates = (select max(rank_literacy_rates) from lit_rates);


-- top 5 districts of Assam with high literacy rate
select 
	District,
    State,
    Literacy, dense_rank() over(order by Literacy desc) as rank_literacy_rates
from dataset1
where State = 'Assam'
limit 5;


-- bottom 5 districts of Assam with very low literacy rate
select 
	District,
    State,
    Literacy, dense_rank() over(order by Literacy desc) as rank_literacy_rates
from dataset1
where State = 'Assam'
order by rank_literacy_rates desc
limit 5;


-- ranking the districts of Assam based on their growth rate
select 
	District,
    State,
    round(100*Growth, 2) AS Growth,
    dense_rank() over(order by Growth desc) as rank_growth_rate
from dataset1
where State = 'Assam';


-- get the district(s) of Assam with the highest growth rate
with pop_gr as
(select 
	District,
    State,
    round(100*Growth, 2) AS Growth,
    dense_rank() over(order by Growth desc) as rank_growth_rate
from dataset1
where State = 'Assam')
select 
	District as district_with_highest_growth_rate,
    Growth
from pop_gr
where rank_growth_rate = 1;


-- get the district(s) of Assam with the lowest growth rate
with pop_gr as
(select 
	District,
    State,
    round(100*Growth, 2) AS Growth,
    dense_rank() over(order by Growth desc) as rank_growth_rate
from dataset1
where State = 'Assam')
select 
	District as district_with_lowest_growth_rate,
    Growth
from pop_gr
where rank_growth_rate = (select max(rank_growth_rate) from pop_gr);


-- top 5 districts of Assam with high growth rates
select 
	District,
    State,
    round(100*Growth, 2) AS Growth,
    dense_rank() over(order by Growth desc) as rank_growth_rate
from dataset1
where State = 'Assam'
limit 5;


-- bottom 5 districts of Assam with very low growth rates
select 
	District,
    State,
    round(100*Growth, 2) AS Growth,
    dense_rank() over(order by Growth desc) as rank_growth_rate
from dataset1
where State = 'Assam'
order by rank_growth_rate desc
limit 5;


-- merge the two datasets so that we can obtain more info about population figures and area size of the district
create table merged_data as
select 
	d1.*,
    d2.Population
from dataset1 d1
left join dataset2_new d2 on d1.District = d2.District and d1.State = d2.State
order by d1.District;


-- check the number of records of the merged dataset
select 
	count(*) as num_of_records
from merged_data;


-- check for null values in the merged dataset
select *
from merged_data
where (District is null) or (Population is null); 


-- Check the districts with same name
select * from dataset2_new
where District in ('Aurangabad', 'Bijapur', 'Bilaspur', 'Hamirpur', 'Pratapgarh', 'Raigarh')
order by District;


-- get the total population of Assam in 2011 Census
select
	State,
    sum(Population) as total_population
from merged_data
group by State
having State = 'Assam';



-- Now coming to the entire country figures

-- get the total population of India
select
	sum(Population) as total_population_of_india
from dataset2_new;


-- top 5 populated states
select 
	State,
    sum(Population) as total_state_population
from merged_data
group by State
order by sum(Population) desc
limit 5;


-- bottom 5 least populated states
select 
	State,
    sum(Population) as total_state_population
from merged_data
group by State
order by sum(Population)
limit 5;


create table lit_popn_data as					# creating a table for literate population of the districts
select 
	District,
    State, 
    Population,
    Literacy,
    round((Literacy * Population)/100, 0) as lit_popn
from merged_data
order by District;


create table gross_state_lit_popn as			# creating a table for total state literate population
select 
	State,
    sum(Population) as state_popn,
    sum(lit_popn) as total_state_lit_popn
from lit_popn_data
group by State;


create table state_lit_rate						# creating a table for the State literacy rate
select 
	State,
    round(100 * total_state_lit_popn/state_popn, 2) as state_literacy_rate
from gross_state_lit_popn
order by State;


-- top 5 most literate states
select 
	State,
    state_literacy_rate
from state_lit_rate
order by state_literacy_rate desc
limit 5;


-- bottom 5 least literate states
select 
	State,
    state_literacy_rate
from state_lit_rate
order by state_literacy_rate
limit 5;


-- merging the state literacy rate data to the merged data
create table merged_data_2 as
select 
	md.*,
    st_lr.state_literacy_rate
from merged_data md
left join state_lit_rate st_lr 
	on md.State = st_lr.State;
    

create table num_of_females_males as			# creating a table for total number of females and males
select 
	District,
    State,
    Sex_Ratio,
    Population,
    round((Population / (1000 + Sex_Ratio)) * Sex_Ratio, 0) as num_of_females,
    round(((Population / (1000 + Sex_Ratio)) * 1000), 0) as num_of_males
from merged_data_2
order by District;


create table total_females_males				# creating a table for aggregating the number of females and males to get the total
select
	State, 
    sum(Population) as total_state_population,
    sum(num_of_females) as total_num_females,
    sum(num_of_males) as total_num_males
from num_of_females_males
group by State
order by State;


create table state_sex_ratio_df as				# craeting a table for state sex ratio
select
	*,
    round(((total_num_females / total_num_males) * 1000), 0) as state_sex_ratio
from total_females_males
order by round(((total_num_females / total_num_males) * 1000), 0) desc;


create table merged_data_3 as					# merging thhe state sex ratio data with merged_data_2
select md2.*, ssr.state_sex_ratio
from merged_data_2 md2
left join state_sex_ratio_df ssr 
	on md2.State = ssr.State
order by State;


-- top 5 states with best sex ratio
select
	State,
    state_sex_ratio
from merged_data_3
group by State
order by state_sex_ratio desc
limit 5;


-- bottom 5 states with very low sex ratio
select
	State,
    state_sex_ratio
from merged_data_3
group by State
order by state_sex_ratio
limit 5;


-- Assam's sex ratio
select
	State,
    state_sex_ratio
from merged_data_3
where State = 'Assam'
limit 1;


-- which districts of Assam are having a greater sex ratio than its State's sex ratio
select
	District,
    State,
    Sex_Ratio,
    state_sex_ratio
from merged_data_3
where State = 'Assam' and Sex_Ratio > state_sex_ratio
order by Sex_ratio;


-- which states are having a greater sex ratio than Assam
select
	State,
    state_sex_ratio
from merged_data_3
where state_sex_ratio > (select state_sex_ratio from merged_data_3 where State = 'Assam' limit 1)
group by State
order by state_sex_ratio;


-- Assam's literacy rate
select
	State,
    state_literacy_rate
from merged_data_3
where State = 'Assam'
limit 1;


-- which districts of Assam are having a greater literacy rate than its State
select
	District,
    State,
    Literacy,
    state_literacy_rate
from merged_data_3
where State = 'Assam' and Literacy > state_literacy_rate
order by Literacy;


-- which states are having a greater sex ratio than Assam
select
	State,
    state_literacy_rate
from merged_data_3
where state_literacy_rate > (select state_literacy_rate from merged_data_3 where State = 'Assam' limit 1)
group by State
order by state_literacy_rate;


SELECT * FROM indian_2011_census.merged_data_3;


create table num_of_people_born_district_df as			# creating a table for number of births in each district
select
	District,
    State,
    Growth,
    Population,
    round((Growth * Population), 0) as num_of_people_born_in_district
from merged_data_3
order by District;

select * from num_of_people_born_district_df;


create table state_growth_rate_df as					# creating a table for state growth rate
with total_births_df as
	(select
		State,
		sum(Population) as total_state_popn,
		sum(num_of_people_born_in_district) as total_num_of_births_in_state
	from num_of_people_born_district_df
	group by State
	order by State)
select 
	State,
    total_num_of_births_in_state,
    total_state_popn,
	round(((total_num_of_births_in_state / total_state_popn) * 100), 2) as state_growth_rate
from total_births_df
order by State;
	

create table merged_data_4 as						# merging the state growth rate data with merged_data_3
select 
	md3.*,
    sgr.state_growth_rate
from merged_data_3 md3
left join state_growth_rate_df sgr
	on md3.State = sgr.State;
    
    
-- state with the highest growth rate
select
	State,
    state_growth_rate
from merged_data_4
group by State
order by state_growth_rate desc
limit 1;


-- top 5 states with very high growth rates
select
	State,
    state_growth_rate
from merged_data_4
group by State
order by state_growth_rate desc
limit 5;


-- bottom 5 states with very low growth rates
select
	State,
    state_growth_rate
from merged_data_4
group by State
order by state_growth_rate
limit 5;


-- Assam's growth rate
select
	State,
    state_growth_rate
from merged_data_4
group by State
having State = 'Assam';


-- which districts of Assam are having greater growth rates than its State's growth rate
select 
	District,
	(Growth*100) as district_growth_rate,
    state_growth_rate
from merged_data_4
where State = 'Assam' and (Growth*100) > state_growth_rate
order by District;


create table ne_states as						# creating a table for NE states
select * from merged_data_4
where State in ('Assam', 'Mizoram', 'Nagaland', 'Sikkim', 'Arunachal Pradesh', 'Tripura', 'Meghalaya', 'Manipur');


-- which NE state have highest sex ratio
select 
	State,
    state_sex_ratio
from ne_states
group by State
order by state_sex_ratio desc
limit 1;


-- top 3 NE states with high sex ratio
select 
	State,
    state_sex_ratio
from ne_states
group by State
order by state_sex_ratio desc
limit 3;


-- which NE state have the lowest sex ratio
select 
	State,
    state_sex_ratio
from ne_states
group by State
order by state_sex_ratio
limit 1;


-- bottom 3 NE states with low sex ratio
select 
	State,
    state_sex_ratio
from ne_states
group by State
order by state_sex_ratio
limit 3;


-- NE state with highest literacy rate
select 
	State,
    state_literacy_rate
from ne_states
group by State
order by state_literacy_rate desc
limit 1;


-- NE state with lowest literacy rate
select 
	State,
    state_literacy_rate
from ne_states
group by State
order by state_literacy_rate
limit 1;


-- top 3 NE states with high literacy rates
select 
	State,
    state_literacy_rate
from ne_states
group by State
order by state_literacy_rate desc
limit 3;


-- bottom 3 NE states with low literacy rates
select 
	State,
    state_literacy_rate
from ne_states
group by State
order by state_literacy_rate
limit 3;


-- NE state with highest growth rate
select 
	State,
    state_growth_rate
from ne_states
group by State
order by state_growth_rate desc
limit 1;


-- NE state with lowest literacy rate
select 
	State,
    state_growth_rate
from ne_states
group by State
order by state_growth_rate
limit 1;


-- top 3 NE states with high literacy rates
select 
	State,
    state_growth_rate
from ne_states
group by State
order by state_growth_rate desc
limit 3;


-- bottom 3 NE states with low literacy rates
select 
	State,
    state_growth_rate
from ne_states
group by State
order by state_growth_rate
limit 3;


-- NE state(s) with better literacy rates than Assam
select 
	State,
    state_growth_rate
from ne_states
group by State
having state_growth_rate > (select state_growth_rate from ne_states where State = 'Assam' limit 1)
order by state_growth_rate desc;


-- NE state(s) with better sex ratios than Assam
select 
	State,
    state_sex_ratio
from ne_states
group by State
having state_sex_ratio > (select state_sex_ratio from ne_states where State = 'Assam' limit 1)
order by state_sex_ratio desc;


-- NE state(s) with greater growth rates than Assam
select 
	State,
    state_growth_rate
from ne_states
group by State
having state_growth_rate > (select state_growth_rate from ne_states where State = 'Assam' limit 1)
order by state_growth_rate desc;