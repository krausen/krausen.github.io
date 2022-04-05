---
title: "Window functions in SQL"
date: 2022-04-05T15:06:26+02:00
draft: false
---

## What are window functions anyway?

Window function allow to you to do aggregates and calculations on a partition of rows. This can be useful if, for example you want to add a column that shows a cumulative sum over the category that the row belongs to. They can also be used to efficiently remove duplicate rows.

I have an [automated setup](https://github.com/krausen/sql-window-functions) for populating a PostgreSQL with mock data that can be tested with the queries below. The data is a collection of streamed music songs from a fictional music streaming service containing only the songs from the video game GTA Vice City. Songs don't belong to albums but instead to a radio channel.

## Deduplicate and keeping the latest ingested value

Partition by event_id which is unique, then select only the first row in each partition.

```sql
SELECT COUNT(*) 
FROM 
    (SELECT *,
            ROW_NUMBER() OVER (PARTITION BY (event_id) ORDER BY ingestion_time DESC) AS rn 
    FROM streams) dedup 
WHERE rn=1;
```

## Running count for number of streams

Compute a running count up until the current row.

```sql
SELECT
    event_id,
    song_name,
    stream_started.
    COUNT(*) OVER (PARTITION BY song_id ORDER BY stream_started ROWS BETWEEN UNBOUNDED
    PRECEDING and CURRENT ROW) AS running_total_streams
FROM streams
ORDER BY stream_started;
```

## Show previous and next stream time for song 0

We can look at leading and lagging rows for an individual row.

```sql
SELECT
    event_id,
    song_name,
    stream_started,
    LAG(stream_started, 1) OVER (ORDER BY stream_started) as previous_stream,
    LEAD(stream_started, 1) OVER (ORDER BY stream_started) as previous_stream
FROM streams
WHERE song_id = 0;
```

## Show total number of streams for the song and the total number of streams in the channel

Count the number of streams for a song and the total number of streams for all songs in the channel it belongs to.

```sql
SELECT
    event_id,
    song_name,
    stream_started,
    COUNT(song_id) OVER (PARTITION BY song_id) as total_streams_of_this_song, 
    COUNT(song_id) OVER (PARTITION BY channel) as total_streams_in_channel
FROM streams;
```

# Top 3 ranked songs from each channel

```sql
WITH song_count AS (
    SELECT song_name, COUNT(song_id) AS total_streams_on_channel, channel
    FROM streams
    GROUP BY song_id, song_name, channel
),
song_rank AS (
    SELECT
        song_name,
        channel,
        total_streams_on_channel,
        DENSE_RANK() OVER (PARTITION BY channel ORDER BY total_streams_on_channel DESC) AS rank_on_channel
    FROM song_count
)
SELECT *
FROM song_rank
WHERE rank_on_channel <= 3;
```

# Find the most and least streamed song

```sql
WITH song_count AS (
    SELECT song_name,
    COUNT(song_id) AS total_streams
    FROM streams
    GROUP BY song_id, song_name
)
SELECT song_name, total_streams
FROM (
    SELECT song_name,
           MIN(total_streams) OVER() min_streams,
           MAX(total_streams) OVER() max_streams,
           total_streams
    FROM song_count
) tmp
WHERE total_streams IN (min_streams, max_streams);
```