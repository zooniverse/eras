---
title: Querying Comment Counts
layout: page
nav_order: 3
---

## Querying Comment Counts

We also allow querying comment counts without Authentication (i.e. No Authorization Header within your request).

With comment counts you can also filter your count query by the following parameters:



* project_id/s
    * can search by multiple project_ids when entering a `,` separated string of ids
    * eg. `?project_id=1,2,3,4`
* user_id/s
    * can search by multiple user_ids when entering a `,` separated string of ids
    * eg. `?user_id=1,2,3,4`
* Start_date
    * Date Format must be in `YYYY-MM-DD`
* End_date
    * Date Format must be in `YYYY-MM-DD`
* Period
    * If this is a parameter, the response will include a `data` key which shows the breakdown of comment counts bucketed by your entered period.
    * Allowable buckets are either:
        * `day`
        * `week`
        * `month`
        * `year`


### Example: Querying Comment Counts

If one was curious on how many total comments we currently have on the Zooniverse, you could query with the following:
```
curl -G https://eras.zooniverse.org/comments
```

Response will look something like this:
```
{
  "total_count":1637
}

```

### Example: Querying Comment Counts By Project With Count 	Breakdown

Similar to querying classification counts, our stats API allows querying comment counts by project. The following example shows how one would query for comment counts for a specific project (eg. project with id `1234`) broken down by month.

```
curl -G https://eras.zooniverse.org/comments?period=month&project_id=1234
```

Similar to `/classifications` endpoint, valid `period` buckets are either by `day`, `week`, `month`, `year`.

Response:
```
{
  "total_count": 70,
  "data": [
    {
      "period": "2022-04-01T00:00:00.000Z",
      "count": 5
    },
    {
      "period": "2022-05-01T00:00:00.000Z",
      "count": 6
    },
    {
      "period": "2022-06-01T00:00:00.000Z",
      "count": 34
    },
    {
      "period": "2022-07-01T00:00:00.000Z",
      "count": 19
    },
    {
      "period": "2022-08-01T00:00:00.000Z",
      "count": 1
    },
    {
      "period": "2022-12-01T00:00:00.000Z",
      "count": 1
    },
    {
      "period": "2023-01-01T00:00:00.000Z",
      "count": 4
    }
  ]
}
```