---
title: Examples in Other Languages
layout: page
nav_order: 6
---

# Quick Examples in Other Languages


## Python
```
import requests

api_url = 'https://eras.zooniverse.org/classifications'
headers = {'authorization': f"Bearer {_YOUR_BEARER_TOKEN_}"}

user_classification_counts_url = api_url + '/users/1234'
r = requests.get(user_classification_counts_url, headers=headers)

if r.status_code == 200:
  data = r.json()
  # Do something with data
else:
  print('Error with retrieving data')
```

## Javascript

The following example is an authenticated callout to `/users` where `user_id=1234`
```
import fetch from 'node-fetch'

const apiUrl = 'https://eras.zooniverse.org/classifications'
const headers = { authorization: `Bearer ${_YOUR_BEARER_TOKEN_}`
}

fetch(apiUrl + '/users/1234', { headers })
  .then(response => {
     if (!response.ok) {
       throw new Error('Network response was not ok')
     }
     return response.json();
  })
  .then(data => {
     console.log('Data : ', data);
     // Do something with the data
  })
  .catch(error => {
     console.error('There was an error with fetching data')
   });

```