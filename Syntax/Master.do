/************************************************************************************************
* Author: Scott Latham
* Purpose: This is the master file for the "America's entering kindergarteners" book chapter
*
* Created: 7/4/2014
* Last modified: 11/13/2017
*************************************************************************************************/

	global data "Z:\save here\Scott Latham\ECLS-K data"
	global path "Z:\save here\Scott Latham\America's entering kindergarteners\Generated Datasets"
	
	cd "Z:\save here\Scott Latham\K Today 2\Syntax"

	do "Variable Selection"
	do "Data Cleaning"
	do "Imputing"
	
	//do "R & R Manuscript Tables"
