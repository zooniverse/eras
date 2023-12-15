---
title: Querying Classification Counts (Unauthenticated)
layout: page
nav_order: 2
---

# Querying Classification Counts (Unauthenticated)

We allow querying classification counts without Authentication (i.e. No Authorization Header within your request) if you are querying by the following:



* project_id/s
    * can search by multiple project_ids when entering a `,` separated string of ids
    * eg. `?project_id=1,2,3,4`
* workflow_id/s
    * can search by multiple workflow_ids when entering a `,` separated string of ids
    * eg. `?workflow_id=1,2,3,4`
* Start_date
    * Date Format must be in `YYYY-MM-DD`
* End_date
    * Date Format must be in `YYYY-MM-DD`
* Period
    * If this is a parameter, the response will include a `data` key which shows the breakdown of classification counts bucketed by your entered period.
    * Allowable buckets are either:
        * `day`
        * `week`
        * `month`
        * `year`

**One caveat is that we do not allow you to query by BOTH project_id AND workflow_id (either one or the other).**


### Example: Querying Classification Counts in total for Zooniverse

If one was curious on how many total classifications we currently have on the Zooniverse, you could query the following:

```
curl -G https://eras.zooniverse.org/classifications
```

This will return the total count of classifications of the entire Zooniverse.

Response will look like:
```
{
 "total_count": 770,522,706
}
```


### Example: Querying Classifications for a Specific Project

If interested in querying classification count for a specific project, we can do the following:
```
curl -G https://eras.zooniverse.org/classifications?project_id=1234
```

Response will look like:
```
{
 "total_count": 22,083
}
```


### Example: Querying Classifications for a Specific Project With Count Breakdown

If interested in querying for classification count for a specific project (for eg. project with id `1234`) and also interested in the monthly counts that make up the total count of the response, we can query the following:
```
curl -G https://eras.zooniverse.org/classifications?project_id=1234&period=month
```

Here, we utilize the `?period` parameter to bucket by month. Allowable `period`s are `day`, `week`, `month`, `year`.

Response will look like:
```
{
  "total_count": 377,
  "data": [
    {
      "period": "2022-12-01T00:00:00.000Z",
      "count": 11
    },
    {
      "period": "2023-01-01T00:00:00.000Z",
      "count": 21
    },
    {
      "period": "2023-02-01T00:00:00.000Z",
      "count": 35
    },
    {
      "period": "2023-03-01T00:00:00.000Z",
      "count": 79
    },
    {
      "period": "2023-04-01T00:00:00.000Z",
      "count": 16
    },
    {
      "period": "2023-05-01T00:00:00.000Z",
      "count": 47
    },
    {
      "period": "2023-06-01T00:00:00.000Z",
      "count": 29
    },
    {
      "period": "2023-07-01T00:00:00.000Z",
      "count": 16
    },
    {
      "period": "2023-08-01T00:00:00.000Z",
      "count": 59
    },
    {
      "period": "2023-09-01T00:00:00.000Z",
      "count": 64
    }
  ]
}
```


### Example: Querying Classification Counts for a Specific Project With Count Breakdown Within A Certain Date Range

If interested in querying for classification count for a specific project (for eg. project with id `1234`) between the days of September 18, 2023 and September 22, 2023, and also interested in the daily counts that make up the total count of the response, we can query the following:
```
curl -G https://eras.zooniverse.org/classifications?project_id=1234&period=day&start_date=2023-09-17&end_date=2023-09-24
```

**It is important to note that when entering a date range (a `start_date` or an `end_date` or both), dates entered MUST be in the format YYYY-MM-DD**

Response:
```
{
  "total_count": 41,
  "data": [
    {
      "period": "2023-09-18T00:00:00.000Z",
      "count": 2
    },
    {
      "period": "2023-09-19T00:00:00.000Z",
      "count": 19
    },
    {
      "period": "2023-09-20T00:00:00.000Z",
      "count": 19
    },
    {
      "period": "2023-09-22T00:00:00.000Z",
      "count": 1
    }
  ]
}
```

**The API uses UTC and are strings in the ISO 8601 “combined date and time representation” format (https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations) :**

`2015-05-15T15:50:38Z`


### Example: Querying Classification Counts of Multiple Projects With Count Breakdowns Within A Certain Date Range

If interested in querying the classification counts of multiple projects (for eg. if one was the owner of projects with ID `1234` and `4321`) and were interested in total classification for both projects altogether between the days of May 05, 2015 and June 05, 2015, and also interested in the daily counts that make up the total count of the response, we can query the following:

```
curl -G https://eras.zooniverse.org/classifications?project_id=1234,4321&period=day&start_date-2015-05-05&end_date=2015-08-05
```

**Note that the two project ids are separated by a `,`.**

**We expect the response to give the TOTAL classification count of both projects**



* **i.e. classification counts of project with id 1234 + classification counts of project with id 4321**

Response:
```
{
  "total_count": 76,
  "data": [
    {
      "period": "2015-04-24T00:00:00.000Z",
      "count": 5
    },
    {
      "period": "2015-04-25T00:00:00.000Z",
      "count": 8
    },
    {
      "period": "2015-04-28T00:00:00.000Z",
      "count": 2
    },
    {
      "period": "2015-04-29T00:00:00.000Z",
      "count": 12
    },
    {
      "period": "2015-05-06T00:00:00.000Z",
      "count": 6
    },
    {
      "period": "2015-05-13T00:00:00.000Z",
      "count": 9
    },
    {
      "period": "2015-05-17T00:00:00.000Z",
      "count": 1
    },
    {
      "period": "2015-05-19T00:00:00.000Z",
      "count": 2
    },
    {
      "period": "2015-05-20T00:00:00.000Z",
      "count": 11
    },
    {
      "period": "2015-05-21T00:00:00.000Z",
      "count": 7
    },
    {
      "period": "2015-05-22T00:00:00.000Z",
      "count": 5
    },
    {
      "period": "2015-05-23T00:00:00.000Z",
      "count": 2
    },
    {
      "period": "2015-05-26T00:00:00.000Z",
      "count": 2
    },
    {
      "period": "2015-05-28T00:00:00.000Z",
      "count": 1
    },
    {
      "period": "2015-06-02T00:00:00.000Z",
      "count": 1
    },
    {
      "period": "2015-06-03T00:00:00.000Z",
      "count": 2
    }
  ]
}
```