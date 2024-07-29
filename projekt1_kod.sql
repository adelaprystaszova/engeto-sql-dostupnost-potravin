-- TVORBA PRIMIMÁRNÍ TABULKY

-- data pro otázku:
-- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
SELECT 
	industry_branch_code,
	payroll_year,
	value
FROM czechia_payroll
WHERE value_type_code = 5958 AND industry_branch_code IS NOT NULL
GROUP BY industry_branch_code, payroll_year
ORDER BY industry_branch_code, payroll_year;