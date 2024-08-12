-- Primární tabulka
CREATE OR REPLACE TABLE t_adela_prystaszova_project_SQL_primary_final
WITH wages_in_industries AS (
	WITH wages AS (
		SELECT 
			industry_branch_code,
			payroll_year,
			avg(value) average_wage
		FROM czechia_payroll
		WHERE value_type_code = 5958  AND calculation_code = 100
			AND industry_branch_code IS NOT NULL
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