

DROP TABLE job CASCADE;
DROP TABLE location CASCADE;
DROP TABLE dept CASCADE;
DROP TABLE education_level CASCADE;
DROP TABLE emp CASCADE;
DROP TABLE job_history CASCADE;
DROP TABLE dept_mgr CASCADE;
DROP TABLE address CASCADE;
DROP TABLE city CASCADE;
DROP TABLE state CASCADE;
DROP TABLE salary CASCADE;

CREATE TABLE job(
    job_id SERIAL PRIMARY KEY,
    job_title VARCHAR(100)
);

CREATE TABLE education_level(
    id SERIAL PRIMARY KEY,
    level varchar(50)
);

CREATE TABLE location(
    loc_id SERIAL PRIMARY KEY,
    loc_name varchar(50)
);

CREATE TABLE state(
    state_id SERIAL PRIMARY KEY,
    state_code VARCHAR(2),
    loc_id INT REFERENCES location(loc_id)
);

CREATE TABLE city(
    city_id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    state_id INT REFERENCES state(state_id)
);

CREATE TABLE address(
  add_id SERIAL PRIMARY KEY,
  add_name VARCHAR(100) ,
  city_id INT REFERENCES city(city_id)
);

CREATE TABLE dept(
    dept_id SERIAL PRIMARY KEY,
    dname varchar(50),
    add_id INT REFERENCES address(add_id)
);

CREATE TABLE emp(
    emp_id varchar(8) PRIMARY KEY,
    emp_nm varchar(50),
    email varchar(100),
    hire_dt date,    
    mgr_id varchar(8) REFERENCES emp(emp_id),
    job_id INT REFERENCES job(job_id),
    dept_id INT REFERENCES dept(dept_id),
    edu_lvl INT REFERENCES education_level(id)
);

CREATE TABLE dept_mgr(
    dept_id INT REFERENCES dept(dept_id),
    mgr_id varchar(8) REFERENCES emp(emp_id),
    PRIMARY KEY (dept_id, mgr_id)
);

CREATE TABLE job_history(
    emp_id varchar(8) REFERENCES emp(emp_id),
    start_dt DATE,
    end_dt DATE,
    job_id INT REFERENCES job(job_id),
    dept_id INT REFERENCES dept(dept_id),
    mgr_id VARCHAR(8) REFERENCES emp(emp_id),
    PRIMARY KEY (emp_id, start_dt)
);

CREATE TABLE salary(
    emp_id VARCHAR(8),
    start_dt Date,
    amount INT,
    PRIMARY KEY (emp_id, start_dt),
    FOREIGN KEY (emp_id, start_dt) REFERENCES job_history(emp_id, start_dt)
);




INSERT INTO job(job_title)
SELECT DISTINCT job_title FROM proj_stg;

INSERT INTO education_level(level)
SELECT DISTINCT education_lvl FROM proj_stg;

INSERT INTO location(loc_name)
SELECT DISTINCT location FROM proj_stg;

INSERT INTO state(state_code, loc_id)
SELECT DISTINCT st.state, l.loc_id FROM proj_stg st JOIN location l
ON st.location = l.loc_name;

INSERT INTO city(name, state_id)
SELECT DISTINCT st.city, s.state_id FROM proj_stg st JOIN state s
ON st.state = s.state_code;

INSERT INTO address(add_name, city_id)
SELECT DISTINCT address, city_id FROM proj_stg st JOIN city c
ON st.city = c.name;


INSERT INTO dept(dname, add_id)
SELECT DISTINCT st.department_nm, ad.add_id
FROM  proj_stg st  JOIN address ad
ON st.address = ad.add_name;



INSERT INTO emp
SELECT DISTINCT st.emp_id, st.emp_nm, st.email, st.hire_dt, st1.emp_id as mgr_id, j.job_id, d.dept_id, el.id
FROM proj_stg st LEFT join proj_stg st1
ON st.manager = st1.emp_nm 
JOIN job j
ON st.job_title = j.job_title
JOIN dept d
ON st.department_nm = d.dname 
JOIN address ad
ON st.address = ad.add_name and d.add_id = ad.add_id
JOIN educatiON_level el
ON st.educatiON_lvl = el.level
WHERE to_char(st.end_dt, 'YYYY') = '2100';

INSERT INTO dept_mgr
SELECT DISTINCT d.dept_id, e.emp_id as mgr_id
FROM emp e join proj_stg st
ON e.emp_nm = st.manager 
JOIN dept d
ON st.department_nm = d.dname;



INSERT INTO job_history
select st.emp_id, st.start_dt, st.end_dt, j.job_id, d.dept_id, mgr.emp_id
FROM proj_stg st  LEFT join proj_stg mgr
ON st.manager = mgr.emp_nm
JOIN job j
ON st.job_title = j.job_title
JOIN dept d
ON st.department_nm = d.dname 
JOIN address ad
ON st.address = ad.add_name and d.add_id = ad.add_id;

INSERT INTO salary(emp_id, start_dt, amount)
SELECT DISTINCT emp_id, start_dt, salary from proj_stg;

--Question 1: Return a list of employees with Job Titles and Department Names

SELECT e.emp_id, e.emp_nm, e.email, e.hire_dt, e.mgr_id, j.job_title, d.dname
FROM emp e JOIN job j
ON e.job_id = j.job_id
JOIN dept d
ON e.dept_id = d.dept_id;

--Question 2: Insert Web Programmer as a new job title

INSERT INTO job(job_title)
VALUES('Web programmer');

SELECT * FROM job;

--Question 3: Correct the job title from web programmer to web developer

UPDATE job set job_title = 'Web developer' WHERE job_id='11';

SELECT * FROM job;

--Question 4: Delete the job title Web Developer from the database

DELETE FROM job where job_id = 11;

SELECT * FROM job;

---Question 5: How many employees are in each department?

SELECT d.dname, count(*) num_employee
FROM job_history e JOIN dept d
ON e.dept_id = d.dept_id
group by d.dname;

--Question 6: Write a query that returns current and past jobs (include employee name, job title, department, manager name, start and end date for position) for employee Toni Lembeck.

SELECT e.emp_nm, j.job_title, d.dname, h.start_dt, h.end_dt, mgr.emp_nm as manager
FROM JOB_HISTORY h JOIN emp e
ON h.emp_id = e.emp_id
JOIN job j
ON h.job_id = j.job_id
JOIN dept d
ON h.dept_id = d.dept_id
JOIN emp mgr
ON h.mgr_id = mgr.emp_id
where e.emp_nm = 'Toni Lembeck';


--Create a view that returns all employee attributes; results should resemble initial Excel file


CREATE VIEW hr_dataset as
select h.emp_id emp_id, e.emp_nm, e.email, e.hire_dt, j.job_title, sl.amount, d.dname as department, mgr.emp_nm as manager, h.start_dt, h.end_dt, l.loc_name as location, ad.add_name as address, ct.name as city, s.state_code as state, el.level as "education level" 
FROM job_history h LEFT JOIN emp e
ON h.emp_id = e.emp_id
LEFT JOIN job j
ON h.job_id = j.job_id
LEFT JOIN dept d
ON h.dept_id = d.dept_id
LEFT JOIN emp mgr
ON h.mgr_id = mgr.emp_id
LEFT JOIN address ad
ON  d.add_id = ad.add_id
LEFT JOIN city ct
ON ad.city_id = ct.city_id
LEFT JOIN state s
ON ct.state_id = s.state_id
LEFT JOIN location l
ON l.loc_id = s.loc_id
JOIN education_level el
ON e.edu_lvl = el.id
LEFT JOIN salary sl
ON h.emp_id = sl.emp_id and h.start_dt = sl.start_dt;




//create new schema create schema ODS; 
//create complex table and insert 

create table complex(
    complex_id string not null unique, 
    complex_name string, 
    constraint pk_complex_id primary key (complex_id)); 
    
insert into complex select from staging.complex; 
//create employee table and insert 

create table employee(
    employee_id number, 
    First_name string, 
    Last_name string, 
    Badge_Status string, 
    Work_from string, 
    constraint pk_employee_id primary key (employee_id)); 
insert into employee select from staging.employee; 

//create protocol table and insert 
create table protocol(
    protocol_id number, 
    step_id number, 
    step_name string, 
    constraint pk_protocol_id primary key (protocol_id)); 

insert into protocol select from staging.protocol; 

//create hightouchareas table and insert 

create table hightouchareas(
    spot_id number, 
    high_touch_area string, 
    constraint pk_spot_id primary key (spot_id)); 
    
insert into HighTouchAreas select from staging.HighTouchAreas; 
//create facility table and insert 

create table facility(
    building_id number, 
    building_name string, 
    sqft string, 
    complex_id string, 
    constraint pk_building_id primary key (building_id), constraint fk_complex_id foreign key (complex_id) references complex(complex_id) ); 
    
insert into facility select from staging.facility; 

//create floors table and insert 

create table floors(
    floor_id number, 
    floor_name string, 
    building_id number, 
    constraint pk_floor_id primary key (floor_id), 
    constraint fk_building_id foreign key (building_id) references facility(building_id) ); 
insert into floors select from staging.floors; 

//create rooms table and insert

 create table rooms(
     room_id number, 
     room_name string, 
     floor_id number, 
     building_id number, 
     total_area string, 
     cleaned_area string, 
     constraint pk_room_id primary key (room_id), 
     constraint fk_floor_id foreign key (floor_id) references floors(floor_id), 
     constraint fk_building_id foreign key (building_id) references facility(building_id) ); 
     
insert into rooms select from staging.rooms; 
//create frequency table and insert 


    
insert into frequency select from staging.frequency; 

//create CleaningSchedule table and insert 

create table CleaningSchedule(
    transaction_id number, 
    step_id number, 
    cleaned_on string, 
    frequency_id number, 
    building_id number, 
    floor_id number, 
    room_id number, 
    employee_id number, 
    spot_id number, 
    test_value number, 
    Efficiency number, 
    constraint pk_transaction_id primary key (transaction_id), 
    constraint fk_frequency_id foreign key (frequency_id) references frequency(frequency_id), 
    constraint fk_building_id foreign key (building_id) references facility(building_id), 
    constraint fk_floor_id foreign key (floor_id) references floors(floor_id), 
    constraint fk_room_id foreign key (room_id) references rooms(room_id), 
    constraint fk_employee_id foreign key (employee_id) references employee(employee_id), 
    constraint fk_spot_id foreign key (spot_id) references hightouchareas(spot_id) ); 

insert into CleaningSchedule select * from staging.CleaningSchedule;

//DWH SCHEMA CREATE SCHEMA DWH; /
/DIMEMPLOYEE 
create table DIMEMPLOYEE ( 
    EMPLOYEE_ID NUMBER, 
    FIRST_NAME STRING, 
    LAST_NAME STRING ); 
insert into DIMEMPLOYEE 
select distinct EMPLOYEE_ID, FIRST_NAME, LAST_NAME from ods.EMPLOYEE; 

//DIMPROTOCOL 
create table DIMPROTOCOL( 
    STEP_ID NUMBER, 
    STEP_NAME string ); 
    
insert into DIMPROTOCOL 
select distinct STEP_ID, STEP_NAME from ods.PROTOCOL; 

//DIMHIGHTOUCHAREAS 
create table DIMHIGHTOUCHAREAS( 
    SPOT_ID NUMBER, 
    HIGH_TOUCH_AREA string ); 

insert into DIMHIGHTOUCHAREAS 
select distinct SPOT_ID, HIGH_TOUCH_AREA from ods.HIGHTOUCHAREAS; 

//DIMFREQUENCY 
create table DIMFREQUENCY( 
    FREQUENCY_ID NUMBER, 
    FREQUENCY NUMBER ); 
insert into DIMFREQUENCY select distinct FREQUENCY_ID, FREQUENCY from ods.FREQUENCY; 

//DIMROOM 
create table DIMROOOM( 
    ROOM_ID NUMBER, 
    ROOM_NAME STRING ); 
insert into DIMROOOM select distinct ROOM_ID, ROOM_NAME from ods.ROOMS; 

//DIMFLOORS 

create table DIMFLOORS( 
    FLOOR_ID number, 
    FLOOR_NAME STRING ); 

insert into DIMFLOORS 
select distinct FLOOR_ID, FLOOR_NAME from ods.FLOORS; 

//DIMFACILITY 

create table DIMFACILITY ( 
    BUILDING_ID NUMBER, 
    BUILDING_NAME STRING ); 

insert into DIMFACILITY 
select distinct BUILDING_ID, BUILDING_NAME from ods.FACILITY; 

//DIMCOMPLEX 

create table DIMCOMPLEX ( 
    COMPLEX_ID STRING, 
    COMPLEX_NAME STRING ); 
insert into DIMCOMPLEX select distinct COMPLEX_ID, COMPLEX_NAME from ods.COMPLEX; 

//FACTTABLE 
create table facttable_CleaningSchedule ( 
    TRANSACTION_ID NUMBER, 
    EMPLOYEE_ID NUMBER, 
    FIRST_NAME STRING, 
    LAST_NAME STRING, 
    STEP_ID NUMBER, 
    STEP_NAME string, 
    SPOT_ID NUMBER, 
    HIGH_TOUCH_AREA string, 
    FREQUENCY_ID NUMBER, 
    FREQUENCY NUMBER, 
    ROOM_ID NUMBER, 
    ROOM_NAME STRING, 
    FLOOR_ID number, 
    FLOOR_NAME STRING, 
    BUILDING_ID NUMBER, 
    BUILDING_NAME STRING, 
    COMPLEX_ID STRING, 
    COMPLEX_NAME STRING, 
    SQFT STRING, 
    TOTAL_AREA STRING, 
    CLEANED_AREA STRING, 
    TEST_VALUE NUMBER, 
    EFFICIENCY NUMBER, 
    CLEANED_ON STRING, 
    constraint fk_TRANSACTION_ID foreign key (TRANSACTION_ID) references ods.CLEANINGSCHEDULE (TRANSACTION_ID), 
    constraint fk_EMPLOYEE_id foreign key (EMPLOYEE_id) references ods.EMPLOYEE (EMPLOYEE_id), 
    constraint fk_SPOT_id foreign key (SPOT_id) references ods.HIGHTOUCHAREAS (SPOT_id), 
    constraint fk_FREQUENCY_id foreign key (FREQUENCY_id) references ods.FREQUENCY(FREQUENCY_id), 
    constraint fk_ROOM_id foreign key (ROOM_id) references ods.ROOMS (ROOM_id), 
    constraint fk_FLOOR_id foreign key (FLOOR_id) references ods.FLOORS (FLOOR_id), 
    constraint fk_BUILDING_id foreign key (BUILDING_id) references ods.FACILITY (BUILDING_id), 
    constraint fk_COMPLEX_id foreign key (COMPLEX_id) references ods.COMPLEX (COMPLEX_id) ); 

    
    
insert into facttable_CleaningSchedule 
select 
    S.TRANSACTION_ID, 
    E.EMPLOYEE_ID, 
    E.FIRST_NAME, 
    E.LAST_NAME, 
    P.STEP_ID, 
    P.STEP_NAME, 
    HTA.SPOT_ID, 
    HTA.HIGH_TOUCH_AREA, 
    FQ.FREQUENCY_ID, 
    FQ.FREQUENCY, 
    R.ROOM_ID, 
    R.ROOM_NAME, 
    FL.FLOOR_ID, 
    FL.FLOOR_NAME, 
    F.BUILDING_ID, 
    F.BUILDING_NAME, 
    C.COMPLEX_ID, 
    C.COMPLEX_NAME, 
    F.SQFT, 
    R.TOTAL_AREA, 
    R.CLEANED_AREA, 
    S.TEST_VALUE, 
    S.EFFICIENCY, 
    S.CLEANED_ON 
FROM ODS.EMPLOYEE E,ODS.FACILITY F,ODS.FLOORS FL,ODS.FREQUENCY FQ,ODS.HIGHTOUCHAREAS HTA,ODS.PROTOCOL P,ODS.ROOMS R,ODS.CLEANINGSCHEDULE S,ODS.COMPLEX C 
WHERE (E.EMPLOYEE_ID = S.EMPLOYEE_ID) AND (P.STEP_ID = S.STEP_ID) AND (HTA.SPOT_ID = S.SPOT_ID) AND (FQ.FREQUENCY_ID = S.FREQUENCY_ID) AND (R.ROOM_ID = S.ROOM_ID) AND (FL.FLOOR_ID = R.FLOOR_ID) AND (F.BUILDING_ID = R.BUILDING_ID);


drop table dim_business;
drop table dim_user;
drop table dim_review;
drop table dim_checkin;
drop table dim_covid;
drop table dim_tip;
drop table dim_precipitation;
drop table dim_temperature;
drop table fact_table;

create table dim_business(
    business_id STRING,    
    name STRING,
    constraint pk_business_id primary key(business_id)
);

insert into dim_business
select distinct 
    business_id,    
    name   
from ods.business;

create table dim_user(
  user_id STRING,  
  name STRING,  
  constraint pk_user_id primary key(user_id)
);

insert into dim_user
select distinct 
    user_id,    
    name    
from ods.user;

create table dim_review(
    review_id STRING,      
    date DATE,    
    stars NUMBER,   
    constraint pk_review_id primary key(review_id)
);

insert into dim_review
select  distinct 
 review_id, 
 date, 
 stars 
from ods.review;

create table dim_checkin(
    business_id STRING,
    dates STRING    
);

insert into dim_checkin
select distinct 
    business_id,
    dates
from ods.checkin;

create table dim_covid(
   Call_To_Action_enabled STRING,
   Covid_Banner STRING,
   Grubhub_enabled STRING,
   Request_a_Quote_Enabled STRING,
   Temporary_Closed_Until STRING,
   Virtual_Services_Offered STRING,
   business_id  String,
   delivery_or_takeout STRING,
   highlights STRING   
);

insert into dim_covid
select distinct 
    Call_To_Action_enabled,
    Covid_Banner,
    Grubhub_enabled,
    Request_a_Quote_Enabled,
    Temporary_Closed_Until,
    Virtual_Services_Offered,
    business_id,
    delivery_or_takeout,
    highlights
from ods.covid;

create table dim_tip(   
   compliment_count NUMBER,
   date DATE,   
   business_id STRING,
   user_id STRING   
);

insert into dim_tip
select  distinct   
    compliment_count,
    date,    
    business_id,
    user_id
from ods.tip;


create table dim_precipitation(
    date DATE,
    precipitation STRING,
    precipitation_normal STRING    
);

insert into dim_precipitation
select distinct 
    date,
    precipitation,
    precipitation_normal
from ods.precipitation;

create table dim_temperature(
    date DATE,
    min NUMBER,
    max NUMBER,
    normal_min NUMBER,
    normal_max NUMBER
    
);

insert into dim_temperature
select distinct
    date,
    min,
    max,
    normal_min,
    normal_max
from ods.temperature; 

create table fact_table(
    business_id STRING,
    user_id STRING,
    review_id STRING,
    stars NUMBER,
    date Date,
    constraint fk_dim_user_id foreign key (user_id) references dim_user(user_id),
    constraint fk_dim_business_id foreign key (business_id) references dim_business(business_id),
    constraint fk_dim_review_id foreign key (business_id) references dim_review(review_id)   
    
);

insert into fact_table
select 
    r.business_id,
    r.user_id,
    r.review_id,
    r.stars,
    r.date
from ods.business b, ods.user u, ods.review r
where r.user_id = u.user_id and r.business_id = b.business_id;


select b.name, u.name, r.stars, t.min, t.max, p.precipitation, p.precipitation_normal
from fact_table ft, dim_precipitation p ,dim_temperature t, dim_review r, dim_user u, dim_business b
where ft.user_id  = u.user_id and ft.business_id = b.business_id and ft.date = t.date 
and ft.date = p.date and ft.review_id = r.review_id;

select  ft.stars, t.min, t.max, p.precipitation, p.precipitation_normal
from fact_table ft, dim_precipitation p ,dim_temperature t
where  ft.date = t.date 
and ft.date = p.date;

select  min(date), max(date) from dim_temperature;

select min(date), max(date) from dim_review;

select * from fact_table;

select * from dim_review r, dim_temperature t where r.date = t.date;

select  min(date), max(date) from ods.precipitation;

select min(date), max(date) from dim_review;









    
   
    

 
 
    