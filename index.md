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

