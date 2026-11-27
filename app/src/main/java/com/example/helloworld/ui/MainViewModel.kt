package com.example.helloworld.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.example.helloworld.config.ConfigRepository
import com.example.helloworld.config.ConfigResult
import kotlinx.coroutines.launch

class MainViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = ConfigRepository(application)
    val state = MutableLiveData<ConfigResult>()

    fun load(forceRefresh: Boolean = false) {
        viewModelScope.launch {
            state.postValue(repository.load(forceRefresh))
        }
    }
}
