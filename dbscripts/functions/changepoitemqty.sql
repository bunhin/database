CREATE OR REPLACE FUNCTION changePoitemQty(pPoitemid INTEGER,
                                           pQty NUMERIC) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2012 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  RETURN changePoitemQty(pPoitemid, pQty, false);

END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION changePoitemQty(pPoitemid INTEGER,
                                           pQty NUMERIC,
                                           pBySO BOOLEAN) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2012 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE

BEGIN

  IF ( ( SELECT (poitem_status IN ('C'))
         FROM poitem
         WHERE (poitem_id=pPoitemid) ) ) THEN
    RETURN -1;
  END IF;

  UPDATE poitem
  SET poitem_qty_ordered=pQty
  WHERE (poitem_id=pPoitemid);

  IF (pBySO) THEN
    --Generate the PoItemUpdatedBySo event
    PERFORM postEvent('PoItemUpdatedBySo', 'P', poitem_id,
                      itemsite_warehous_id,
                      (pohead_number || '-'|| poitem_linenumber || ': ' || item_number),
                      NULL, NULL, NULL, NULL)
    FROM poitem JOIN pohead ON (pohead_id=poitem_pohead_id)
                JOIN itemsite ON (itemsite_id=poitem_itemsite_id)
                JOIN item ON (item_id=itemsite_item_id)
    WHERE (poitem_id=pPoitemid)
      AND (poitem_duedate <= (CURRENT_DATE + itemsite_eventfence));
  END IF;

  RETURN pPoitemid;

END;
$$ LANGUAGE 'plpgsql';
