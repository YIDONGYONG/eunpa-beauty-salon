// import map から、controllers/**/*_controller をすべて読み込んで登録します。
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
