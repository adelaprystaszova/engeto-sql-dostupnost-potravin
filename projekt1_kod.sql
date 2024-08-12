-- TVORBA PRIMIMÁRNÍ TABULKY

-- data pro otázku:
-- 1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
CREATE OR REPLACE VIEW v_adela_prystaszova_1 AS 
SELECT 
	industry_branch_code,
	payroll_year,
	avg(value) average_wage
FROM czechia_payroll
WHERE value_type_code = 5958 
	AND calculation_code = 100
	AND industry_branch_code IS NOT NULL
GROUP BY 
	industry_branch_code, 
	payroll_year
ORDER BY 
	industry_branch_code, 
	payroll_year
;

SELECT
	cpib.name industry_branch_name,
	v1.payroll_year,
	v1.average_wage
FROM v_adela_prystaszova_1 v1
LEFT JOIN czechia_payroll_industry_branch cpib
	ON v1.industry_branch_code = cpib.code
;

-- data navíc pro otázky:
-- 2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
-- 3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

CREATE OR REPLACE VIEW v_adela_prystaszova_2 as
SELECT 
	category_code,
	avg(value) average_price,
	year(date_from) price_year
FROM czechia_price cp
GROUP BY 
	category_code, 
	price_year
;

SELECT 
	cpc.name,
	v2.average_price,
	cpc.price_value,
	cpc.price_unit,
	v2.price_year
FROM v_adela_prystaszova_2 v2
JOIN czechia_price_category cpc
	ON v2.category_code = cpc.code
;

/* data navíc pro otázky:
 * 4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 * 5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce,
 * projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
 */
SELECT
	YEAR,
	GDP
FROM economies
WHERE country = 'Czech republic';
