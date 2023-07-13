<h1 align='center'><a href='https://discord.gg/fkM22XjMns'>Discord</a></h1>

---

<h2 align='center'>Information</h2>
System for gangs to capture zones (areas) on the map. Once captured gangs can make money from illegal sales done in the area or money washing.

<h3 align='center'><b><a href='https://www.youtube.com/watch?v=kKPt9KeipG0'>Demonstration Video</a></b></h3>

---

<h2 align='center'>Requirements</h2>

- OneSync <b>Infinity</b>
es_extended
ox_lib
ox_inventory
ultra-voltlab

---

<h2 align='center'>Exports</h2>

<b>Open Menu</b>
<code>TriggerClientEvent('territories:TerritoryInfoMenu')</code>

<b>Sale Complete</b></br>
<code>TriggerServerEvent('territories:sv_Sale', source, zone, type*, amount*, item*, count*)</code>
<i><b>*</b> = Optional. If location is nil you need to supply localPlayerId, and vice-versa.</i>

<i>Example:</i> <code>TriggerServerEvent('territories:sv_Sale', source, GetNameOfZone(GetEntityCoords(PlayerPedId())), 'moneywash')</code>

---
