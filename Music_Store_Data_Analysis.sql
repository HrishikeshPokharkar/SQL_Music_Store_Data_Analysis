create database music_database;
use music_database;

/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */
select * from employee
order by levels desc
limit 1;

/* Q2: Which countries have the most Invoices? */
select billing_country, count(billing_country) as c from invoice
group by billing_country
order by c desc;

/* Q3: What are top 3 values of total invoice? */
select * from invoice
order by total desc
limit 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
select billing_city, sum(total) from invoice
group by billing_city
order by sum(total) desc
limit 1;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
select c.customer_id, first_name, last_name, sum(total) from customer as c
inner join invoice as i
on c.customer_id = i.customer_id
group by c.customer_id, first_name, last_name
order by sum(total) desc
limit 1;

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

/*Method 1 */

SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoiceline ON invoice.invoice_id = invoiceline.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

/*Method 2 */

select distinct c.email , c.first_name, c.last_name, g.name  from customer as c
inner join invoice as i
on c.customer_id = i.customer_id
inner join invoice_line as L
on i.invoice_id = L.invoice_id
inner join track as t
on L.track_id = t.track_id
inner join genre as g
on t.genre_id = g.genre_id
where g.name = 'Rock' 
order by email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select at.artist_id, at.name, count(at.artist_id) from track as t
inner join album as a
on t.album_id = a.album_id
inner join artist as at
on a.artist_id = at.artist_id
inner join genre as g
on t.genre_id = g.genre_id
where g.name = 'Rock'
group by at.artist_id, at.name
order by count(at.artist_id) desc
limit 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name, milliseconds from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc;

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

select customer.customer_id, customer.first_name, customer.last_name, Big_artist.artist_id, Big_artist.name,
sum(invoice_line.unit_price*invoice_line.quantity) 
from 
(select artist.artist_id, artist.name, sum(invoice_line.unit_price*invoice_line.quantity) from invoice_line
join track on invoice_line.track_id = track.track_id 
join album on track.album_id = album.album_id
join artist on artist.artist_id = album.artist_id
group by artist.name, artist.artist_id
order by 3 desc) as Big_artist
join album on Big_artist.artist_id = album.artist_id
join track on track.album_id = album.album_id
join invoice_line on invoice_line.track_id = track.track_id
join invoice on invoice.invoice_id = invoice_line.invoice_id
join customer on customer.customer_id = invoice.customer_id
group by 1,2,3,4,5
order by 5,6 desc

/* Q2: Find how much amount spent by top customer of top selling artist? Write a query to return customer name, artist name and total spent */

/*Method 1 */

select customer.customer_id, customer.first_name, customer.last_name, Big_artist.artist_id, Big_artist.name,
sum(invoice_line.unit_price*invoice_line.quantity) 
from 
(select artist.artist_id, artist.name, sum(invoice_line.unit_price*invoice_line.quantity) from invoice_line
join track on invoice_line.track_id = track.track_id 
join album on track.album_id = album.album_id
join artist on artist.artist_id = album.artist_id
group by artist.name, artist.artist_id
order by 3 desc
limit 1) as Big_artist
join album on Big_artist.artist_id = album.artist_id
join track on track.album_id = album.album_id
join invoice_line on invoice_line.track_id = track.track_id
join invoice on invoice.invoice_id = invoice_line.invoice_id
join customer on customer.customer_id = invoice.customer_id
group by 1,2,3,4,5
order by 6 desc

/*Method 2: Using CTE (Common Table Expression) */

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1,2
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* Method 3: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

/* Q3: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/*Method 1 */

select quantity , country, name, genre_id, rowno from
(
select count(invoice_line.quantity) as quantity ,customer.country as country, genre.name, genre.genre_id,
row_number() over(partition by customer.country order by count(invoice_line.quantity) desc) as rowno
from invoice_line
join invoice on invoice.invoice_id = invoice_line.invoice_id
JOIN customer ON customer.customer_id = invoice.customer_id
join track on invoice_line.track_id = track.track_id
join genre on track.genre_id = genre.genre_id
group by customer.country, genre.name, genre.genre_id
order by country asc, count(invoice_line.quantity) desc
) as xyz
where rowno =1

/*Method 2: Using CTE-(Common Table Expression) */

with popular_genre as
(
select count(invoice_line.quantity),customer.country, genre.name, genre.genre_id,
row_number() over(partition by customer.country order by count(invoice_line.quantity) desc) as rowno
from invoice_line
join invoice on invoice.invoice_id = invoice_line.invoice_id
JOIN customer ON customer.customer_id = invoice.customer_id
join track on invoice_line.track_id = track.track_id
join genre on track.genre_id = genre.genre_id
group by customer.country, genre.name, genre.genre_id
order by country asc, count(invoice_line.quantity) desc
)
 SELECT * FROM popular_genre WHERE RowNo <= 1

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
-For countries where the top amount spent is shared, provide all customers who spent this amount. */

/*Method 1 */

select customer_id , first_name, last_name, billing_country, total_spending , Row_No 
from
(
select customer.customer_id , first_name, last_name, billing_country, sum(total) as total_spending,
row_number() over(partition by billing_country order by sum(total) desc) as Row_No
from customer
join invoice on invoice.customer_id = customer.customer_id
group by customer.customer_id, first_name, last_name, billing_country
order by  billing_country asc, sum(total) desc
) as xyz
where Row_No <= 1

/*Method 2 : using CTE(Common Table Expression) */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1

/* Method 3: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;
