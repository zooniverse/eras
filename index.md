---
title: Home
layout: home
has_toc: true
nav_order: 1
---

# How to Use Our Stats Service API

Our stats service API allows our volunteers, project owners and project contributors to view their efforts and contributions to project/s.

Our Stats API uses HTTP GET requests with JSON arguments and JSON responses. You can view here ([https://github.com/zooniverse/eras/wiki/API-Callout-Examples](https://github.com/zooniverse/eras/wiki/API-Callout-Examples))  for full documentation and more callout examples.

In this site, we provide common examples project owners or user group admins might use in order to query specific volunteer classification/comment counts.


### Differences Between eras.zooniverse.org vs Defunct stats.zooniverse.org

If you are familiar with our older stats service ([https://github.com/zooniverse/zoo-event-stats](https://github.com/zooniverse/zoo-event-stats); [https://stats.zooniverse.org/](https://stats.zooniverse.org/)),  there are some key differences between the new service [https://eras.zooniverse.org](https://eras.zooniverse.org) and the old service [https://stats.zooniverse.org/](https://stats.zooniverse.org/).



* **Differences in the Requests**
    * URL changes
        * No need to include `/counts` in URL for eras.zooniverse.org
        * Period is now a parameter (`?period`) vs a fixed part of URL
        * Period is not a required parameter in eras.zooniverse.org
        * Eras.zooniverse.org uses pluralized version of `classifications` and `comments`
            * Eg. [https://eras.zooniverse.org/classifications?period=week](https://eras.zooniverse.org/classifications?period=week) vs [https://stats.zooniverse.org/counts/classification/week](https://eras.zooniverse.org/classification/week)
    * Valid `period`s are now only:
        * Day
        * Week
        * Month
        * Year
    * Some requests in eras.zooniverse.org will require an Authorization Header
* **Differences in Responses**
    * Responses of [https://eras.zooniverse.org](https://eras.zooniverse.org) will only return the total counts unless you specify a `period` you want to bucket your data by.
    * Response keys are different
        * [https://eras.zooniverse.org](https://eras.zooniverse.org) Response Example:
        * [https://stats.zooniverse.org](https://stats.zooniverse.org) Response Example:


## Querying Classification Counts By User Group


### What Are User Groups?

As a new feature of our stats service, we introduce the idea of user groups so that a group of volunteers can set shared goals and celebrate milestones. Whether it’s a classroom, after school club, a group of friends, or corporate volunteering program, this new group feature provides new avenues for fostering community and collaboration for our volunteers and contributors.

For more documentation on user groups within our stats service, you can view our documentation: here (https://github.com/zooniverse/eras/wiki/API-Callout-Examples#classificationsuser_groupsid)

Our stats API allows querying for a user group’s classification stats as long as the person querying has proper authorizations to access the group statistics. _In other words, querying classification counts by user group requires an authentication token to be supplied. _

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


### Example: Query User Group Classification Counts

If you were interested in the user group with user_group id=1234’s classification counts of all time. You will need your user_group_id and run the following:

Response:

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


### Example: Query User Group’s Group Member Stats Breakdown

If you were interested in the user group with user_group id=1234’s group member stats breakdown of all time, we can utilize the `?individual_stats_breakdown=true` parameter and request the following:

Response:

Note that in this particular response, it returns a list of each group member’s project contributions, session time and classification count, ordered by top total classification count of members in the group.


## Examples in Other Languages


### Python


### Javascript

The following example is an authenticated callout to `/users` where `user_id=1234`
