class_name ReplayAssertions


static func market_trace(trace: Array[Dictionary]) -> Array[Dictionary]:
	var markets: Array[Dictionary] = []
	for checkpoint: Dictionary in trace:
		if not checkpoint["market"].is_empty():
			markets.append(checkpoint["market"].duplicate(true))
	return markets


static func street_deal_trace(trace: Array[Dictionary]) -> Array[Dictionary]:
	var deals: Array[Dictionary] = []
	for checkpoint: Dictionary in trace:
		if not checkpoint["street_deal"].is_empty():
			deals.append(checkpoint["street_deal"].duplicate(true))
	return deals


static func contact_offer_trace(trace: Array[Dictionary]) -> Array:
	var offers: Array = []
	for checkpoint: Dictionary in trace:
		if not checkpoint["contact_offer_ids"].is_empty():
			offers.append(checkpoint["contact_offer_ids"].duplicate())
	return offers
