---
title: Classification Counts By User Group
layout: page
nav_order: 5
---

# Querying Classification Counts By User Group


### What Are User Groups?

As a new feature of our stats service, we introduce the idea of user groups so that a group of volunteers can set shared goals and celebrate milestones. Whether it’s a classroom, after school club, a group of friends, or corporate volunteering program, this new group feature provides new avenues for fostering community and collaboration for our volunteers and contributors.

For more documentation on user groups within our stats service, you can view our Github repository Wiki: here (https://github.com/zooniverse/eras/wiki/API-Callout-Examples#classificationsuser_groupsid)

Our stats API allows querying for a user group’s classification stats as long as the person querying has proper authorizations to access the group statistics. _In other words, querying classification counts by user group requires an authentication token to be supplied._

This authentication token is known as a bearer token and is usually supplied as a HTTP `Authorization` header with the value prefixed by `Bearer` and then the token data.


---

You can query user group classification counts filtering by any of the following:



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
* top_contributors (integer)
    * Limit that dictates whether your response will show top contributors of the user group
* individual_stats_breakdown (true/false)
    * Boolean that dictates whether your response will shows show a roster stats report per each individual member for the user group


## Example: Query User Group Classification Counts

If you were interested in the user group with user_group id=1234’s classification counts of all time. You will need your user_group_id and run the following:

```
curl -G https://eras.zooniverse.org/classifications/user_groups/1234
--header 'Authorization: Bearer $YOUR_BEARER_TOKEN'
```

Response:

```
{
  "total_count": 18,
  "time_spent": 4895.192,
  "active_users": 2,
  "project_contributions": [
    {
      "project_id": 335,
      "count": 4,
      "session_time": 61.971000000000004
    },
    {
      "project_id": 1613,
      "count": 3,
      "session_time": 4744.13
    },
    {
      "project_id": 1952,
      "count": 3,
      "session_time": 50.400999999999996
    },
    {
      "project_id": 1663,
      "count": 2,
      "session_time": 6.649000000000001
    },
    {
      "project_id": 1767,
      "count": 2,
      "session_time": 4.567
    },
    {
      "project_id": 1783,
      "count": 2,
      "session_time": 4.545
    },
    {
      "project_id": 1634,
      "count": 1,
      "session_time": 17.469
    },
    {
      "project_id": 631,
      "count": 1,
      "session_time": 5.46
    }
  ]
}
```

The response for querying user group classification counts will look a bit different than the other queries from the previous examples. By default, querying user group classification counts will return the following:



* Total_count
    * Integer
    * The total count of classifications of queried user group
* Time_spent
    * Float
    * Total session time IN SECONDS of total classifications of user group
* Active_users
    * Integer
    * Total active users of the user group
    * Active users being users who have made a classification given request parameters
* Project_contributions
    * List
    * List of all project contributions (project_id and count) of user group given request parameters
    * NOTE: if `project_id` or `workflow_id` is a parameter in your request, the response will NOT include this list
* data
    * Only returned when `period` is a request parameter
    * This shows the total breakdown of classifications of the user group bucketed by `period` that make up the response’s `total_count`


## Example: Query User Group’s Group Member Stats Breakdown

If you were interested in the user group with user_group id=1234’s group member stats breakdown of all time, we can utilize the `?individual_stats_breakdown=true` parameter and request the following:
```
curl -G https://eras.zooniverse.org/classifications/user_groups/1234?individual_stats_breakdown=true
--header 'Authorization: Bearer $YOUR_BEARER_TOKEN'
```

Response:
```
{
  "group_member_stats_breakdown": [
    {
      "user_id": 1325316,
      "count": 12,
      "session_time": 121.761,
      "project_contributions": [
        {
          "project_id": 1952,
          "count": 3,
          "session_time": 50.400999999999996
        },
        {
          "project_id": 1783,
          "count": 2,
          "session_time": 4.545
        },
        {
          "project_id": 1767,
          "count": 2,
          "session_time": 4.567
        },
        {
          "project_id": 1663,
          "count": 2,
          "session_time": 6.649000000000001
        },
        {
          "project_id": 335,
          "count": 2,
          "session_time": 38.129999999999995
        },
        {
          "project_id": 1634,
          "count": 1,
          "session_time": 17.469
        }
      ]
    },
    {
      "user_id": 1326056,
      "count": 6,
      "session_time": 4773.4310000000005,
      "project_contributions": [
        {
          "project_id": 1613,
          "count": 3,
          "session_time": 4744.13
        },
        {
          "project_id": 335,
          "count": 2,
          "session_time": 23.841
        },
        {
          "project_id": 631,
          "count": 1,
          "session_time": 5.46
        }
      ]
    }
  ]
}
```

Note that in this particular response, it returns a list of each group member’s project contributions, session time and classification count, ordered by top total classification count of members in the group.

