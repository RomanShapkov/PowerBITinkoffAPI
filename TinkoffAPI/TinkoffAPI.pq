// This file contains your Data Connector logic
section TinkoffAPI;

token = Extension.CurrentCredential()[Key];


[DataSource.Kind="TinkoffAPI", Publish="TinkoffAPI.Publish"]
shared TinkoffAPI.GetBankAccounts = () =>
    let
        url = "https://business.tinkoff.ru/openapi/api/v3/bank-accounts",
        header = [
            #"Authorization" = "Bearer " &token,
            #"Content-Type" = "application/json"
            ],
        option = [Headers = header, ManualCredentials = true],
        data = Json.Document(Web.Contents(url, option)),
        table = toTable(data)
    in
        table;


TinkoffAPI.GetBankOperation = (account) =>
    let
        url = "https://business.tinkoff.ru/openapi/api/v1/bank-statement",
        header = [
            #"Authorization" = "Bearer " &token,
            #"Content-Type" = "application/json"
            ],
        option = [Headers = header, ManualCredentials = true],
        data = Json.Document(Web.Contents(url, option)),
        table = toTable(data)
    in
        table;

// Data Source Kind description
TinkoffAPI = [
    Authentication = [
           Key = [],
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
TinkoffAPI.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = TinkoffAPI.Icons,
    SourceTypeImage = TinkoffAPI.Icons
];

TinkoffAPI.Icons = [
    Icon16 = { Extension.Contents("TinkoffAPI16.png"), Extension.Contents("TinkoffAPI20.png"), Extension.Contents("TinkoffAPI24.png"), Extension.Contents("TinkoffAPI32.png") },
    Icon32 = { Extension.Contents("TinkoffAPI32.png"), Extension.Contents("TinkoffAPI40.png"), Extension.Contents("TinkoffAPI48.png"), Extension.Contents("TinkoffAPI64.png") }
];


toTable = (lstrec as list, optional index as number) as table =>
    let
        fieldnames = 
            let
                toprows = if index is null then lstrec else List.FirstN(lstrec, index),
                listfields = List.Transform(toprows, Record.FieldNames),
                namesdistinct = List.Union(listfields)
            in
                namesdistinct,
        tbl = Table.FromRecords(lstrec, fieldnames, MissingField.UseNull)
    in
        tbl;