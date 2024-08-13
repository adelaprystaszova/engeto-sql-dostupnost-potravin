-- PRIMÁRNÍ TABULKA
CREATE OR REPLACE TABLE t_adela_prystaszova_project_SQL_primary_final
WITH wages_in_industries AS (
	WITH wages AS (
		SELECT 
			industry_branch_code,
			payroll_year,
			avg(value) average_wage
		FROM czechia_payroll
		WHERE value_type_code = 5958  
			AND calculation_code = 100
		GROUP BY 
			industry_branch_code, 
			payroll_year
		ORDER BY 
			industry_branch_code, 
			payroll_year
	)
	SELECT 
		cpib.name industry_branch_name,
		w.payroll_year,
		w.average_wage
	FROM wages w
	LEFT JOIN czechia_payroll_industry_branch cpib
		ON w.industry_branch_code = cpib.code
),
food_prices AS (
	WITH prices AS (
		SELECT 
			category_code,
			avg(value) average_price,
			year(date_from) price_year
		FROM czechia_price
		GROUP BY 
			category_code, 
			price_year
	)
	SELECT 
		cpc.name,
		p.average_price,
		cpc.price_value,
		cpc.price_unit,
		p.price_year
	FROM prices p
	LEFT JOIN czechia_price_category cpc
		ON p.category_code = cpc.code
),
economy AS (
	SELECT
		YEAR,
		GDP
	FROM economies
	WHERE country = 'Czech Republic'
)
SELECT
	wii.industry_branch_name odvetvi,
	wii.payroll_year rok,
	wii.average_wage prumerna_mesicni_mzda_v_kc,
	fp.name potravina,
	fp.average_price prumerna_cena_potraviny,
	fp.price_value mnozstvi_potraviny,
	fp.price_unit jednotka_potraviny,
	ec.gdp HDP
FROM wages_in_industries wii
INNER JOIN food_prices fp
	ON wii.payroll_year = fp.price_year
LEFT JOIN economy ec
	ON wii.payroll_year = ec.year
ORDER BY 
	wii.industry_branch_name,
	wii.payroll_year
;

-- SEKUNDÁRNÍ TABULKA
CREATE OR REPLACE TABLE t_adela_prystaszova_project_SQL_secondary_final
SELECT
	co.country stat,
	ec.`year` rok,
	ec.population populace,
	ec.GDP HDP,
	ec.gini giniho_koeficient
FROM countries co
LEFT JOIN economies ec
	ON co.country = ec.country
WHERE co.continent = 'Europe' 
	AND ec.`year` BETWEEN 2006 AND 2018
ORDER BY 
	co.country,
	ec.`year`
;



-- PODKLADY K ZODPOVĚZENÍ OTÁZEK


-- 1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-- Nárůst průměrných měsíčních mezd v jednotlivých odvětvích mezi roky 2006 a 2018 (v procentech):
SELECT DISTINCT
	t1.odvetvi,
	t1.prumerna_mesicni_mzda_v_kc mzda_2006,
	t2.prumerna_mesicni_mzda_v_kc mzda_2018,
	round((t2.prumerna_mesicni_mzda_v_kc - t1.prumerna_mesicni_mzda_v_kc)/t1.prumerna_mesicni_mzda_v_kc*100, 2) AS narust_mzdy_v_procentech
FROM t_adela_prystaszova_project_sql_primary_final t1
INNER JOIN t_adela_prystaszova_project_sql_primary_final t2
	ON t1.odvetvi = t2.odvetvi AND t1.rok = t2.rok-12
ORDER BY 
	t1.odvetvi
;
-- Nárůst průměrných měsíčních mezd v odvětvích v jednotlivých letech (v procentech):
SELECT DISTINCT
	t1.odvetvi,
	t1.rok,
	t1.prumerna_mesicni_mzda_v_kc mzda,
	t2.rok nasledujici_rok,
	t2.prumerna_mesicni_mzda_v_kc mzda_v_nasledujicim_roce,
	round((t2.prumerna_mesicni_mzda_v_kc - t1.prumerna_mesicni_mzda_v_kc)/t1.prumerna_mesicni_mzda_v_kc*100, 2) AS narust_mzdy_v_procentech
FROM t_adela_prystaszova_project_sql_primary_final t1
INNER JOIN t_adela_prystaszova_project_sql_primary_final t2
	ON t1.odvetvi = t2.odvetvi 
	AND t1.rok = t2.rok-1
ORDER BY 
	t1.odvetvi,
	t1.rok
;
-- Odvětví a roky, ve kterých průměrné měsíční mzdy poklesly:
SELECT DISTINCT
	t1.odvetvi,
	t1.rok,
	t1.prumerna_mesicni_mzda_v_kc mzda,
	t2.rok nasledujici_rok,
	t2.prumerna_mesicni_mzda_v_kc mzda_v_nasledujicim_roce,
	round((t2.prumerna_mesicni_mzda_v_kc - t1.prumerna_mesicni_mzda_v_kc)/t1.prumerna_mesicni_mzda_v_kc*100, 2) AS narust_mzdy_v_procentech
FROM t_adela_prystaszova_project_sql_primary_final t1
INNER JOIN t_adela_prystaszova_project_sql_primary_final t2
	ON t1.odvetvi = t2.odvetvi 
	AND t1.rok = t2.rok-1 
WHERE round((t2.prumerna_mesicni_mzda_v_kc - t1.prumerna_mesicni_mzda_v_kc)/t1.prumerna_mesicni_mzda_v_kc*100, 2) < 0
ORDER BY 
	t1.odvetvi,
	t1.rok
;


-- 2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
SELECT
	t1.potravina,
	concat(round(t1.prumerna_mesicni_mzda_v_kc/t1.prumerna_cena_potraviny, 0), ' ', t1.jednotka_potraviny) mnozstvi_za_prumernou_mzdu_2006,
	concat(round(t2.prumerna_mesicni_mzda_v_kc/t2.prumerna_cena_potraviny, 0), ' ', t1.jednotka_potraviny) mnozstvi_za_prumernou_mzdu_2018
FROM t_adela_prystaszova_project_sql_primary_final t1
LEFT JOIN t_adela_prystaszova_project_sql_primary_final t2
	ON t1.rok = t2.rok-12 AND t1.potravina = t2.potravina
WHERE
	t1.potravina IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
	AND t1.rok = '2006'
	AND t1.odvetvi IS NULL  
	AND t2.odvetvi IS NULL 
ORDER BY
	t1.odvetvi,
	t1.potravina desc
;


-- 3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
SELECT DISTINCT
	t1.potravina,
	avg(round((t2.prumerna_cena_potraviny - t1.prumerna_cena_potraviny)/t1.prumerna_cena_potraviny*100, 2)) prumerny_mezirocni_narust_ceny_v_procentech
FROM t_adela_prystaszova_project_sql_primary_final t1
INNER JOIN t_adela_prystaszova_project_sql_primary_final t2
	ON t1.potravina = t2.potravina 
	AND t1.rok = t2.rok-1
WHERE t1.potravina != 'Jakostní víno bílé'
GROUP BY t1.potravina
ORDER BY 
	avg(round((t2.prumerna_cena_potraviny - t1.prumerna_cena_potraviny)/t1.prumerna_cena_potraviny*100, 2))
;


-- 4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
SELECT
	t2.rok,
	avg(round((t2.prumerna_cena_potraviny - t1.prumerna_cena_potraviny)/t1.prumerna_cena_potraviny*100, 2)) narust_cen_v_procentech,
	round((t2.prumerna_mesicni_mzda_v_kc - t1.prumerna_mesicni_mzda_v_kc)/t1.prumerna_mesicni_mzda_v_kc*100, 2) AS narust_mezd_v_procentech
FROM t_adela_prystaszova_project_sql_primary_final t1
INNER JOIN t_adela_prystaszova_project_sql_primary_final t2
	ON t1.potravina = t2.potravina 
	AND t1.rok = t2.rok-1
WHERE t1.odvetvi IS NULL  
	AND t2.odvetvi IS NULL
GROUP BY t1.rok
ORDER BY 
	t1.rok
;


-- prumerny narust cen potravin
SELECT
	t1.rok,
	t2.rok nasledujici_rok,
	avg(round((t2.prumerna_cena_potraviny - t1.prumerna_cena_potraviny)/t1.prumerna_cena_potraviny*100, 2)) narust_ceny_v_procentech
FROM t_adela_prystaszova_project_sql_primary_final t1
INNER JOIN t_adela_prystaszova_project_sql_primary_final t2
	ON t1.potravina = t2.potravina 
	AND t1.rok = t2.rok-1
GROUP BY t1.rok
	ORDER BY 
	t1.rok
;

-- narust celkove prumerne mzdy:
SELECT DISTINCT
	v1.rok,
	v2.rok nasledujici_rok,
	round((v2.prumerna_mesicni_mzda_v_kc - v1.prumerna_mesicni_mzda_v_kc)/v1.prumerna_mesicni_mzda_v_kc*100, 2) AS narust_mezd_v_procentech
FROM t_adela_prystaszova_project_sql_primary_final v1
INNER JOIN t_adela_prystaszova_project_sql_primary_final v2
	ON v1.rok = v2.rok-1 AND v1.potravina = v2.potravina
WHERE v1.odvetvi IS NULL  
	AND v2.odvetvi IS NULL 
;



/* 5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
 * projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
 */
