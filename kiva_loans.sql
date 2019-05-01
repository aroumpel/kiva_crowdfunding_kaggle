  delete FROM [KIVA_1].[dbo].[kiva_loans_s]
  WHERE [id] like '%id%'
  ;
  drop TABLE [KIVA_1].[dbo].[kiva_loans]
  ;
CREATE TABLE [KIVA_1].[dbo].[kiva_loans](
    [loanId] [INT] primary key,
	[id] [INT]  null,
	[activity] [varchar](30) NULL,
	[sector] [varchar](15) NULL,
	[use] [varchar](800) NULL,
	[COUNTRY_ID] [INT] NULL,
	[regionId] [INT] NULL,
	[currency] [varchar](3) NULL,
	[partnerId] [INT] NULL,
	[posted_time] [date] NULL,
	[term_in_months] [INT] NULL,
	[lender_count] [INT] NULL,
	[tags] [varchar](1400) NULL,
	[borrower_genders] [varchar](400) NULL,
	[repayment_interval] [varchar](10) NULL,
	[lenderSex] [varchar](10) NULL
) 
;
insert into [KIVA_1].[dbo].[kiva_loans]
SELECT ROW_NUMBER() OVER(ORDER BY [id])
      ,cast([id] as int)
      ,trim([activity])
      ,trim(l.[sector])
      ,trim([use])
      ,c.COUNTRY_ID
	  ,r.[regionId]
      , trim([currency])
	  ,p.partnerId
      ,cast (substring([posted_time], 1, 10)  as date) as posted_time
      ,cast (l.[term_in_months] as decimal(3,0)) 
      ,cast([lender_count] as int)
      ,trim([tags])
      ,trim([borrower_genders])
      ,trim([repayment_interval])
	  ,case when [borrower_genders] is null then null
	        when [borrower_genders] not like '%female%' then 'male'
			when [borrower_genders] not like '%male%' then 'female'
			else 'both' end
  FROM [KIVA_1].[dbo].[kiva_loans_s] l
  left join [KIVA_1].[dbo].[COUNTRYDIM] c
  on c.country = l.country
  left join (select distinct [region] , [regionId]
             from [KIVA_1].[dbo].[loan_themes_x_region]) r
  on r.[region] = l.region
  left join [KIVA_1].[dbo].[partnerDim] p
  on p.Partner_ID = cast (l.[Partner_ID] as decimal(3,0)) 
  ;
  update [KIVA_1].[dbo].[kiva_loans]
  set lenderSex = 'female'
  where [borrower_genders]  is not null
  ;
  update [KIVA_1].[dbo].[kiva_loans]
  set lenderSex = (
     case when (borrower_genders not like '%female%') then 'male'  
          when (borrower_genders like 'male, %' or borrower_genders like '%, male%') then 'both' 
		  else 'female'
 end)
  where [borrower_genders]  is not null
  ;
  drop table [KIVA_1].[dbo].[loan_mvmt] 
  ;
  create table [KIVA_1].[dbo].[loan_mvmt] (
  [mvmt_id] [int] primary key, 
  [loanId] [INT] not null,
  [timeId] [int] not null,
  [dt] [date],
  [type] [char](1),
  amount [decimal](10,1)
  )
  ;
  insert into [KIVA_1].[dbo].[loan_mvmt] 
    select ROW_NUMBER() OVER(ORDER BY [id], [dt], [type])         
        ,loanId
		,DateKey
	    ,dt
	    ,type
		,amount 
  from (
  SELECT 
       l.loanId as loanId
	  ,l.id
	  ,d.DateKey
      ,cast (substring([disbursed_time], 1, 10)  as date) as dt
      ,'D' as type
      ,cast([loan_amount] as decimal(10,1)) as amount

  FROM [KIVA_1].[dbo].[kiva_loans_s] s
  join [KIVA_1].[dbo].[kiva_loans] l
  on l.id = s.id
  join [KIVA_1].[dbo].DateDimension d
  on d.Date = cast (substring([disbursed_time], 1, 10)  as date)
  union   
  SELECT l.loanId as loanId
      ,l.id
	  ,d.DateKey
      ,cast (substring([funded_time], 1, 10)  as date) as dt
      ,'F' as type
      ,cast([funded_amount] as decimal(10,1)) as amount

  FROM [KIVA_1].[dbo].[kiva_loans_s] s
  join [KIVA_1].[dbo].[kiva_loans] l
  on l.id = s.id
  join [KIVA_1].[dbo].DateDimension d
  on d.Date = cast (substring([funded_time], 1, 10)  as date)
  ) a
  ;
  drop table [KIVA_1].[dbo].loan_x_loantheme
  ;
  create table [KIVA_1].[dbo].loan_x_loantheme (
  loanId [int] not null,
  LoanThemeDim_id [int] null
  )
  ;
  insert into [KIVA_1].[dbo].loan_x_loantheme
    SELECT 
    l.loanId
   ,t.LoanThemeDim_id
  FROM [KIVA_1].[dbo].[kiva_loans] l
  left join [KIVA_1].[dbo].[loan_theme_ids_s] x
  on x.id = l.id
  left join [KIVA_1].[dbo].[LoanThemeDim] t
  on t.Loan_Theme_ID = x.Loan_Theme_ID
  ;
  delete from [KIVA_1].[dbo].loan_x_loantheme
  where LoanThemeDim_id is null
  --(40847 rows affected)
  ;
  delete 
  FROM [KIVA_1].[dbo].[loan_mvmt]
  where [dt] is null
  --(52360 rows affected)