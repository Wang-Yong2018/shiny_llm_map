library(DiagrammeR)
grViz('digraph music_sales {
  graph [rankdir=LR, fontname="Arial", fontsize=10];
  node [shape=box, style="rounded,filled", fillcolor=lightblue, fontname="Arial"];
  edge [fontname="Arial", fontsize=8];
  
  Invoices [label="Invoices\n(InvoiceId, CustomerId,\nInvoiceDate, BillingState, Total)"];
  Invoice_items [label="Invoice_items\n(InvoiceId, TrackId,\nUnitPrice, Quantity)"];
  Tracks [label="Tracks\n(TrackId, Name, AlbumId)"];
  Albums [label="Albums\n(AlbumId, Title, ArtistId)"];
  Artists [label="Artists\n(ArtistId, Name)"];
  
  Invoices -> Invoice_items [label="1:N", head=crow];
  Invoice_items -> Tracks [label="N:1", head=crow];
  Tracks -> Albums [label="N:1", head=crow];
  Albums -> Artists [label="N:1", head=crow];
}')
