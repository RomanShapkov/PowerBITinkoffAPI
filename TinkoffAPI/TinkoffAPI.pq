// This file contains your Data Connector logic
section TinkoffAPI;

token = Extension.CurrentCredential()[Key];

[DataSource.Kind="TinkoffAPI", Publish="TinkoffAPI.Publish"]

shared TinkoffAPI.NavTableNested = () as table =>
    let

        NavTable = (tb as table) => Table.ToNavigationTable(tb, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf"),
        table_header = {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},
        lv1 = #table(
            table_header,
            {
                {"BankAccounts", "BankAccounts", TinkoffAPI.GetBankAccounts(), "table", "table", "true"},
                {"GetBankStatement", "GetBankStatement", TinkoffAPI.GetBankStatement, "function", "function", "true"},
                {"GetBankOperation", "GetBankOperation", TinkoffAPI.GetBankOperation, "function", "function", "true"},
                {"GetALLAccountBankOperation", "GetALLAccountBankOperation", TinkoffAPI.GetALLAccountBankOperation, "function", "function", "true"}
            }   
        )
    in
        NavTable(lv1);


TinkoffAPI.GetBankAccounts = () =>
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


TinkoffAPI.GetBankStatement = (account as text, from as date, till as date) =>
    let
        url = "https://business.tinkoff.ru/openapi/api/v1/bank-statement",
        header = [
            #"Authorization" = "Bearer " &token,
            #"Content-Type" = "application/json"
            ],

        params = [
            accountNumber = account,
            from = Date.ToText(from, "yyyy-MM-dd"), 
            till = Date.ToText(till, "yyyy-MM-dd")
            ],

        options = [
            Headers = header, 
            Query = params, 
            ManualCredentials = true
            ],

        data = Json.Document(Web.Contents(url, options))
    in
        data;


TinkoffAPI.GetBankOperation = (account as text, from as date, till as date) =>
    let
        data = TinkoffAPI.GetBankStatement(account, from, till),
        operation = data[operation],
        table = toTable(operation)
    in
        table;

TinkoffAPI.GetALLAccountBankOperation = (from as date, till as date) =>
    let
        accounts = TinkoffAPI.GetBankAccounts()[accountNumber],
        data = List.Transform(accounts, each TinkoffAPI.GetBankStatement( _, from, till)[operation]),
        combine = List.Combine(data),
        table = toTable(combine)
    in
        table;


// Data Source Kind description
TinkoffAPI = [
TestConnection = (dataSourcePath) => {"TinkoffAPI.NavTableNested"},
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


Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;