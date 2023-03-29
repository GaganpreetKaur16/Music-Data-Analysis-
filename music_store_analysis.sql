
# SHOW GLOBAL VARIABLES LIKE 'FOREIGN_KEY_CHECKS';
# SET FOREIGN_KEY_CHECKS=0;


# showing all the tables in the database
SHOW TABLES;

# MUSIC ANALYSIS 
/* ---------------------------------------------------------------------------------------------*/
/* Q: How many artists, albums, tracks and genres are there? */

SELECT COUNT(*) FROM artist;
# There are 275 artists in total.

SELECT COUNT(*) FROM album;
# There are 347 albums in total.

SELECT COUNT(*) FROM track;
# There are 3497 total tracks.

SELECT COUNT(*) FROM genre;
# There are total 25 genres.

/* ----------------------------------------------------------------------------------------------------*/
/* Q: Top 10 countries with most number of invoices? */

SELECT billing_country, COUNT(invoice_id) as no_of_invoices
	FROM invoice
    GROUP BY billing_country
    ORDER BY no_of_invoices DESC
    LIMIT 10;
    
/* -------------------------------------------------------------------------------------------- */    
/* Q: Top 10 Values of invoices and which country they belong to */

# lets see the table 
SELECT * FROM invoice;

SELECT billing_country, billing_city, total 
FROM invoice 
ORDER BY total DESC 
LIMIT 10;

/* ----------------------------------------------------------------------------------------- */
/* Q: Top 10 Customers who spent most , the city and country to which they belong to */
# using joins
SELECT CONCAT(c.first_name, ' ', c.last_name) AS cus_name, c.country, 
SUM(i.total) AS total_spent
FROM customer c 
JOIN invoice i ON 
c.customer_id = i.customer_id
GROUP BY cus_name
ORDER BY total_spent DESC
LIMIT 10;

# ----------------------------------------------------------------------------------
/* Q: Which genre is most popular in Canada? 
Lets find top 5 genres of which tracks are bought the most by the customers in Canada
 by using joins */

SELECT genre.name, SUM(invoice.total) AS total_amount
 FROM genre 
JOIN track ON 
genre.genre_id = track.genre_id
JOIN invoice_line ON 
track.track_id = invoice_line.track_id
JOIN invoice ON
invoice_line.invoice_id = invoice.invoice_id 
JOIN Customer ON 
invoice.customer_id = customer.customer_id 
WHERE customer.Country = "Canada"
GROUP BY genre.name
ORDER BY invoice.total DESC
LIMIT 5;


# ------------------------------------------------------------------------------------
/* Q. Find out if there are any customers who bought music from every genre.
Which city they belong to ? */
# lets find out how many genres are there

SELECT * FROM genre;

# lets use joins to join the tables genre with the invoice information 


/*SELECT CONCAT(customer.first_name,' ',customer.last_name), genre.name 
FROM customer 
JOIN invoice ON
customer.customer_id = invoice.customer_id
JOIN invoice_line ON
invoice.invoice_id = invoice_line.invoice_id 
JOIN track ON 
invoice_line.track_id = track.track_id
JOIN genre ON
track.genre_id = genre.genre_id
WHERE name in ( SELECT name FROM genre);
*/

# -----------------------------------------------------------------------------------------
/*Q: Find the name & ID of the artists who do not have albums ? */

SELECT artist_id, name 
FROM artist 
WHERE artist_id NOT IN 
(SELECT artist_id FROM album);

# or


SELECT artist.name,
       artist.artist_id,
       album.title 
FROM artist
LEFT JOIN album
ON artist.artist_id = album.artist_id
WHERE album.title IS NULL;

# Lets count how many are they 
SELECT COUNT(*)
FROM artist 
WHERE artist_id NOT IN 
(SELECT artist_id FROM album);

# There are total 71 artists who do not have any albums

#-------------------------------------------------------------------------------------------
/* Q. Are there any customers who have a different city listed in their billing address
compared to the address in their information table 
*/


SELECT first_name, last_name, city, billing_city
FROM customer 
INNER JOIN invoice ON 
customer.customer_id = invoice.customer_id
WHERE city != billing_city;

# there are not any customers who have mentioned a different city in their billing address
# compared to the city in their address 

#---------------------------------------------------------------------------------------
/* Q: Find the list of the names of the managers and the employees who reports to them.
*/

SELECT CONCAT(M.first_name,' ' , M.last_name) AS Manager, M.title, 
       CONCAT(E.first_name,' ' , E.last_name) AS Employee, E.title
FROM Employee E 
INNER JOIN Employee M 
ON 
E.reports_to = M.employee_id;

#-------------------------------------------------------------------------------------------
/* Q: Find out the most popular genre for each country. 
Lets say that the most popular genre would be the 
genre with the highest amount of purchases. 
Lets write a query that returns the counrty along with the top genre.

( For the countries where the maximum number of purchases is shared, reutun all the genres)
*/

# Lets see how the countries are related to the genres and purchase 

WITH most_popular_genre AS 
(SELECT invoice.billing_country, genre.name, SUM(invoice_line.unit_price) as total_amount,
RANK() OVER(PARTITION  BY invoice.billing_country ORDER BY SUM(invoice_line.unit_price) DESC)
 AS ranking
FROM invoice
INNER JOIN invoice_line ON 
invoice.invoice_id = invoice_line.invoice_id
INNER JOIN track ON 
track.track_id  = invoice_line.track_id
INNER JOIN genre ON 
genre.genre_id = track.genre_id
GROUP BY invoice.billing_country, genre.name
ORDER BY invoice.billing_country, total_amount DESC)
SELECT billing_country, name, total_amount, ranking 
FROM most_popular_genre
WHERE ranking <= 1       
;


#--------------------------------------------------------------------------------------------
/* Q. Find the total number of Invoices for each customer along with the customer's full name,
city and email. */

# we will join the two tables customer and invoice using inner join and Order the results by number of invoices in descending order 

SELECT CONCAT(customer.first_name, ' ', customer.last_name) AS customer_name,
 customer.email, customer.city,
 COUNT(invoice.customer_id) AS total_invoices
 FROM customer 
 INNER JOIN invoice ON 
 customer.customer_id = invoice.customer_id 
 GROUP BY customer_name
 ORDER BY total_invoices DESC;
 
 
 # ----------------------------------------------------------------------------------------------
/* Q: Find out all the invoices from Edmonton, Vancouver and Toronto. */

SELECT invoice_id, customer_id, billing_city, total 
FROm invoice 
WHERE billing_city IN ('Edmonton','Vancouver','Toronto');


#--------------------------------------------------------------------------------
/* Q: Find out the customer from each country that have spent most on the music?
  */

 WITH most_spent_by_customer AS (
		SELECT customer.customer_id,
        CONCAT(first_name, ' ' , last_name) AS customer_name,
        billing_country,
        SUM(total) AS total_spent,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS ranking
		FROM invoice
		JOIN customer ON 
        customer.customer_id = invoice.customer_id
		GROUP BY customer_name
        ORDER BY total_spent DESC)
SELECT * FROM most_spent_by_customer
 WHERE ranking <= 1;
 
#-----------------------------------------------------------------------------------------------
/* Q: Write a query to find the most purchased track of each year?
*/
SELECT 
track.name, 
YEAR(invoice.invoice_date) as track_year,
COUNT(invoice_line.invoice_line_id) AS no_of_times,
RANK() OVER(PARTITION BY (YEAR(invoice.invoice_date)) )
FROM track
INNER JOIN invoice_line ON
track.track_id  = invoice_line.track_id 
INNER JOIN invoice ON
invoice_line.invoice_id = invoice.invoice_id 
GROUP BY track_year
ORDER BY no_of_times DESC;


#---------------------------------------------------------------------------
# Q: Write a query to find the most purchased track of 2017?

# Lets see if we do have any data of year 2017 

SELECT * FROM invoice 
WHERE YEAR(invoice_date) = 2017;

# Lets say the most popular track of the year 2017 would be the most purchased track of that year 
# most purchased track of year 2017 

SELECT 
	track.name AS track_name,
    COUNT(invoice_line.invoice_line_id) AS no_of_times_purchased
FROM track
INNER JOIN invoice_line ON 
track.track_id = invoice_line.track_id 
INNER JOIN invoice ON 
invoice_line.invoice_id  = invoice.invoice_id 
WHERE YEAR(invoice.invoice_date)= 2017
GROUP BY track_name
ORDER BY no_of_times_purchased DESC 
LIMIT 1 
;

# So War Pigs is the track that was most popular in the year 2017 

#---------------------------------------------------------------------------------
/* Q: Write a query that shows top 5 most purchased track of all times */

SELECT
		track.name AS track_name,
        COUNT(invoice_line.invoice_line_id) AS no_of_times_purchased
FROM track
INNER JOIN invoice_line ON 
track.track_id = invoice_line.track_id
GROUP BY track_name 
ORDER BY no_of_times_purchased DESC 
LIMIT 5;

# War Pigs, Highway Chile, Changes, Are you Experienced? and Hey Joe are top 5 tracks of all time 
	
#---------------------------------------------------------------------------------------
/* Q:Write a query to find the top 3 selling artists ?
Lets find out the artists whose tracks have been purchased the most 
*/

SELECT
		artist.name AS name_of_artist,
        COUNT(invoice_line.invoice_line_id) AS no_of_times_purchased
FROM track
INNER JOIN invoice_line ON 
track.track_id = invoice_line.track_id
INNER JOIN album ON 
album.album_id = track.album_id 
INNER JOIN artist ON 
artist.artist_id  = album.artist_id
GROUP BY name_of_artist 
ORDER BY no_of_times_purchased DESC 
LIMIT 3 
;

#------------------------------------------------------
/* Q: Write a query to show the number of customers assigned to each agent.
*/

SELECT 
        CONCAT(employee.first_name, ' ' , employee.last_name) AS sales_agent,
        COUNT(customer.customer_id) AS no_of_customers
FROM employee 
INNER JOIN customer ON 
employee.employee_id = customer.support_rep_id
GROUP BY sales_agent;

#-------------------------------------------------------------
/* Q: Which sales agent made the most in each year ?
 */
 
WITH 
	max_sales AS
(SELECT 
        CONCAT(employee.first_name, ' ' , employee.last_name) AS sales_agent,
        ROUND(SUM(invoice.total),2) AS total_sales
FROM employee 
INNER JOIN customer ON 
employee.employee_id = customer.support_rep_id
INNER JOIN invoice ON 
customer.customer_id = invoice.customer_id
GROUP BY sales_agent
)
SELECT 
		sales_agent, MAX(total_sales)
FROM max_sales;

# Jane Peacock is the most sucessfull sales agent with max sales.

#------------------------------------------------------------------------------------
/* Q: Write a query to find the most purchased media type.
*/

# lets find out first the no of times each media is purchased 
SELECT 
		media_type.name AS media,
        COUNT(invoice_line.invoice_line_id) AS no_of_times_purchased
FROM 
invoice_line
INNER JOIN track ON 
track.track_id =invoice_line.track_id 
INNER JOIN media_type ON 
track.media_type_id = media_type.media_type_id
GROUP BY media;
# most purchased media 
WITH most_media_type AS 
( 
SELECT 
		media_type.name AS media,
        COUNT(invoice_line.invoice_line_id) AS no_of_times_purchased
FROM 
invoice_line
INNER JOIN track ON 
track.track_id =invoice_line.track_id 
INNER JOIN media_type ON 
track.media_type_id = media_type.media_type_id
GROUP BY media
)
SELECT media, MAX(no_of_times_purchased)
		FROM most_media_type
;

#------------------------------------------------------------------------------------------

/* Q: Write a query to find the type of the media not purchased */
SELECT 
	media_type.name 
FROM media_type
WHERE media_type.name NOT IN (
SELECT 
		media_type.name 
FROM media_type
INNER JOIN track ON 
track.media_type_id = media_type.media_type_id 
INNER JOIN invoice_line ON 
invoice_line.track_id = track.track_id
) ;
# We have verified that there are not any types of media that was never purchased 


#--------------------------------------------------------------------------------------------
/* Q: Write a query to find the number of invoices per country.
*/
SELECT 
		billing_country,
        COUNT(invoice_id) AS no_of_invoices 
FROM invoice 
GROUP BY billing_country;





















































    