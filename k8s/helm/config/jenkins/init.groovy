import hudson.plugins.locale.PluginImpl
import jenkins.install.InstallState
import jenkins.model.Jenkins
import net.sf.json.JSONObject

println 'Running custom Groovy init script to configure things not supported by CasC plugin...'

def jenkins = Jenkins.get()

println 'Disabling localization...'
def localePlugin = jenkins.getPlugin(PluginImpl)
JSONObject json = new JSONObject()
json.put('systemLocale', 'en_US')
json.put('ignoreAcceptLanguage', true)
localePlugin.configure(null, json)
localePlugin.save()

println 'Disabling usage statistics...'
jenkins.setNoUsageStatistics(true)

println 'Disabling setup wizard...'
jenkins.setInstallState(InstallState.RUNNING)

println 'Saving changes...'
jenkins.save()
