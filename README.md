# eventually_reject

A simple motoko actor that will eventually reject all non-exchange rate proposals before the voting window closes.

It checks open votes every 8 hours and votes to reject anything within 12 hours of close.

It uses the timer API to set up a new time each time it checks.

You can view the current log of what it has voted for at 

This currently does not support SNS governance, but the types look close enough that it would be fairly easy to implement, and we'd take pull requests.

https://nmiv5-haaaa-aaaam-abgaa-cai.raw.ic0.app/
