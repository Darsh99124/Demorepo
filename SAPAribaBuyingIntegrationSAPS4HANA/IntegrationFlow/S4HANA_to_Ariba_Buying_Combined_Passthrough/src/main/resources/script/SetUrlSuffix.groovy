import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;

def Message processData(Message message)
{
    map = message.getProperties();
    MessageType = map.get("MessageType");

    if (MessageType == "BNSCompanyCodeMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","CompanyCode");
    } else if (MessageType == "PurchasingOrganisationMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","PurchasingOrg");
    } else if (MessageType == "PlantMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","Plant");
    } else if (MessageType == "PlantPurchasingOrgMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","PlantPurchasingOrg");
    } else if (MessageType == "PurchasingGroupMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","PurchasingGroup");
    } else if (MessageType == "PurchaseDocumentItemCategoryMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","PurchaseDocumentItemCategory");
    } else if (MessageType == "AccountAssignmentCategoryMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","AccountAssignmentCategory");
    } else if (MessageType == "BNSGLAccountMasterDataReplicationBulkRequest") {
      message.setProperty("MessageType","GLAccount");
    } else if (MessageType == "BNSInternalOrderMasterDataReplicationBulkRequest") {
      message.setProperty("MessageType","InternalOrder");
    } else if (MessageType == "BNSCostCentreMasterDataReplicationBulkRequest") {
      message.setProperty("MessageType","CostCentre");
    } else if (MessageType == "WBSElementMasterDataReplicationBulkRequest") {
      message.setProperty("MessageType","WBSElement");
    } else if (MessageType == "MaterialGroupMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","MaterialGroup");
    } else if (MessageType == "BNSTaxCodeMasterDataReplicationBulkRequest") {
      message.setProperty("MessageType","TaxCode");
    } else if (MessageType == "CurrencyMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","Currency");
    } else if (MessageType == "ExchangeRateMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","ExchangeRate");
    } else if (MessageType == "BNSPaymentMethodMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","PaymentMethod");
    } else if (MessageType == "BNSPaymentTermsMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","PaymentTerms");
    } else if (MessageType == "IncotermsMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","Incoterms");
    } else if (MessageType == "RegionMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","Region");
    } else if (MessageType == "UnitOfMeasurementMasterDataReplicationBundleRequest") {
      message.setProperty("MessageType","UnitOfMeasurement");
    } else if (MessageType == "BNSFixedAssetMasterDataReplicationBulkRequest") {
      message.setProperty("MessageType","Asset");
    } else if (MessageType == "UserMasterDataReplicationBulkRequest") {
      message.setProperty("MessageType","User");
    } else if (MessageType == "ProductMDMBulkReplicateRequestMessage") {
      message.setProperty("MessageType","Product");
    }

    return message;
    }
